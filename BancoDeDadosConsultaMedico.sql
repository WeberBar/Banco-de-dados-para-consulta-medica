-- CRIAÇÃO DO BANCO DE DADOS 

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- -----------------------------------------------------
-- Schema ConsultaMedica
-- -----------------------------------------------------
CREATE SCHEMA IF NOT EXISTS `ConsultaMedica` DEFAULT CHARACTER SET utf8mb3 ;
USE `ConsultaMedica` ;

-- Tabelas
CREATE TABLE IF NOT EXISTS `especialidade` (
  `idespecialidade` INT NOT NULL AUTO_INCREMENT,
  `nome` VARCHAR(200) NOT NULL,
  PRIMARY KEY (`idespecialidade`),
  UNIQUE INDEX `nome_UNIQUE` (`nome` ASC))
ENGINE = InnoDB DEFAULT CHARACTER SET = utf8mb3;

CREATE TABLE IF NOT EXISTS `profissionais` (
  `idprofissionais` INT NOT NULL AUTO_INCREMENT,
  `nome` VARCHAR(255) NOT NULL,
  `celular` VARCHAR(20),
  `email` VARCHAR(255) NOT NULL,
  `numero_licenca` VARCHAR(50) NOT NULL,
  `biografia` VARCHAR(255),
  `aceita_convenio` TINYINT NOT NULL,
  `especialidade_idespecialidade` INT NOT NULL,
  PRIMARY KEY (`idprofissionais`, `especialidade_idespecialidade`),
  UNIQUE INDEX `email_UNIQUE` (`email`),
  UNIQUE INDEX `numero_licenca_UNIQUE` (`numero_licenca`),
  INDEX `fk_profissionais_especialidade1_idx` (`especialidade_idespecialidade`),
  CONSTRAINT `fk_profissionais_especialidade1`
    FOREIGN KEY (`especialidade_idespecialidade`)
    REFERENCES `especialidade` (`idespecialidade`))
ENGINE = InnoDB DEFAULT CHARACTER SET = utf8mb3;

CREATE TABLE IF NOT EXISTS `usuarios` (
  `idusuarios` INT NOT NULL AUTO_INCREMENT,
  `nome` VARCHAR(255) NOT NULL,
  `celular` VARCHAR(20),
  `email` VARCHAR(255) NOT NULL,
  `data_de_nascimento` DATE NOT NULL,
  PRIMARY KEY (`idusuarios`),
  UNIQUE INDEX `email_UNIQUE` (`email`))
ENGINE = InnoDB DEFAULT CHARACTER SET = utf8mb3;

CREATE TABLE IF NOT EXISTS `consultas` (
  `idconsultas` INT NOT NULL AUTO_INCREMENT,
  `data` DATE NOT NULL,
  `hora` TIME NOT NULL,
  `status` VARCHAR(45) NOT NULL,
  `observacao` VARCHAR(255),
  `usuarios_idusuarios` INT NOT NULL,
  `profissionais_idprofissionais` INT NOT NULL,
  PRIMARY KEY (`idconsultas`, `usuarios_idusuarios`, `profissionais_idprofissionais`),
  INDEX `fk_consultas_usuarios_idx` (`usuarios_idusuarios`),
  INDEX `fk_consultas_profissionais1_idx` (`profissionais_idprofissionais`),
  CONSTRAINT `fk_consultas_profissionais1`
    FOREIGN KEY (`profissionais_idprofissionais`)
    REFERENCES `profissionais` (`idprofissionais`),
  CONSTRAINT `fk_consultas_usuarios`
    FOREIGN KEY (`usuarios_idusuarios`)
    REFERENCES `usuarios` (`idusuarios`))
ENGINE = InnoDB DEFAULT CHARACTER SET = utf8mb3;

CREATE TABLE IF NOT EXISTS `avaliacoes` (
  `idavaliacoes` INT NOT NULL AUTO_INCREMENT,
  `nota` INT NOT NULL,
  `comentario` VARCHAR(255),
  `data_avaliacao` DATE,
  `consultas_idconsultas` INT NOT NULL,
  PRIMARY KEY (`idavaliacoes`, `consultas_idconsultas`),
  INDEX `fk_avaliacoes_consultas1_idx` (`consultas_idconsultas`),
  CONSTRAINT `fk_avaliacoes_consultas1`
    FOREIGN KEY (`consultas_idconsultas`)
    REFERENCES `consultas` (`idconsultas`))
ENGINE = InnoDB DEFAULT CHARACTER SET = utf8mb3;

CREATE TABLE IF NOT EXISTS `disponibilidade` (
  `iddisponibilidade` INT NOT NULL AUTO_INCREMENT,
  `hora` TIME NOT NULL,
  `data` DATE NOT NULL,
  `disponivel` TINYINT NOT NULL DEFAULT '1',
  `profissionais_idprofissionais` INT NOT NULL,
  PRIMARY KEY (`iddisponibilidade`, `profissionais_idprofissionais`),
  UNIQUE INDEX `data_UNIQUE` (`data`),
  INDEX `fk_disponibilidade_profissionais1_idx` (`profissionais_idprofissionais`),
  CONSTRAINT `fk_disponibilidade_profissionais1`
    FOREIGN KEY (`profissionais_idprofissionais`)
    REFERENCES `profissionais` (`idprofissionais`))
ENGINE = InnoDB DEFAULT CHARACTER SET = utf8mb3;

-- Continuação: Procedures, Views, Triggers e Inserts adaptados para o schema ConsultaMedica

USE `ConsultaMedica`;

-- PROCEDURE: sp_agendar_consulta
DELIMITER $$
CREATE DEFINER=`usermysql`@`%` PROCEDURE `sp_agendar_consulta`(
    IN p_id_usuario INT,
    IN p_id_profissional INT,
    IN p_data DATE,
    IN p_hora TIME,
    IN p_observacao VARCHAR(255)
)
BEGIN
    DECLARE v_disponivel TINYINT;

    SELECT `disponivel` INTO v_disponivel
    FROM `disponibilidade`
    WHERE `profissionais_idprofissionais` = p_id_profissional
      AND `data` = p_data
      AND `hora` = p_hora;

    IF v_disponivel IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erro: Horário inexistente na agenda do profissional.';
    ELSEIF v_disponivel = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erro: Este horário já está ocupado.';
    ELSE
        INSERT INTO `consultas`
            (`data`, `hora`, `status`, `observacao`, `usuarios_idusuarios`, `profissionais_idprofissionais`)
        VALUES
            (p_data, p_hora, 'agendada', p_observacao, p_id_usuario, p_id_profissional);
        SELECT 'Consulta agendada com sucesso!' AS resultado;
    END IF;
END$$
DELIMITER ;

-- PROCEDURE: cancelar_consulta
DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `cancelar_consulta`(
    IN p_idConsulta INT
)
BEGIN
    DECLARE v_idMedico INT;
    DECLARE v_data DATE;
    DECLARE v_hora TIME;
    DECLARE v_status_atual VARCHAR(45);

    SELECT profissionais_idprofissionais, `data`, `hora`, `status`
    INTO v_idMedico, v_data, v_hora, v_status_atual
    FROM `consultas`
    WHERE idconsultas = p_idConsulta;

    IF v_status_atual IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erro: Consulta não encontrada.';
    ELSEIF v_status_atual = 'cancelada' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erro: Esta consulta já foi cancelada.';
    ELSE
        UPDATE `consultas`
        SET `status` = 'cancelada'
        WHERE idconsultas = p_idConsulta;

        UPDATE `disponibilidade`
        SET `disponivel` = 1
        WHERE profissionais_idprofissionais = v_idMedico
          AND `data` = v_data
          AND `hora` = v_hora;

        SELECT 'Consulta cancelada e horário liberado com sucesso.' AS resultado;
    END IF;
END$$
DELIMITER ;

-- PROCEDURE: concluir_consulta
DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `concluir_consulta`(
    IN p_idConsulta INT,
    IN p_novas_observacoes TEXT
)
BEGIN
    DECLARE v_idMedico INT;
    DECLARE v_data DATE;
    DECLARE v_hora TIME;
    DECLARE v_status_atual VARCHAR(50);
    DECLARE v_obs_atual TEXT;

    SELECT profissionais_idprofissionais, `data`, `hora`, `status`, `observacao`
    INTO v_idMedico, v_data, v_hora, v_status_atual, v_obs_atual
    FROM `consultas`
    WHERE idconsultas = p_idConsulta;

    IF v_status_atual IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erro: Consulta não encontrada.';
    ELSEIF v_status_atual = 'concluida' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erro: Esta consulta já foi concluída anteriormente.';
    ELSEIF v_status_atual = 'cancelada' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erro: Não é possível concluir uma consulta que foi cancelada.';
    ELSE
        UPDATE `consultas`
        SET 
            `status` = 'concluida',
            `observacao` = CONCAT_WS('\n---\nObservações do Profissional:\n', v_obs_atual, p_novas_observacoes)
        WHERE idconsultas = p_idConsulta;

        UPDATE `disponibilidade`
        SET `disponivel` = 1
        WHERE profissionais_idprofissionais = v_idMedico
          AND `data` = v_data
          AND `hora` = v_hora;

        SELECT 'Consulta concluída, observações adicionadas e horário liberado com sucesso.' AS resultado;
    END IF;
END$$
DELIMITER ;

-- VIEW: vw_detalhes_consultas
CREATE OR REPLACE VIEW `vw_detalhes_consultas` AS
SELECT 
  c.idconsultas AS id_consulta,
  c.data,
  c.hora,
  c.status,
  u.nome AS nome_paciente,
  p.nome AS nome_profissional,
  e.nome AS especialidade_profissional,
  c.observacao AS observacoes_consulta
FROM consultas c
JOIN usuarios u ON c.usuarios_idusuarios = u.idusuarios
JOIN profissionais p ON c.profissionais_idprofissionais = p.idprofissionais
JOIN especialidade e ON p.especialidade_idespecialidade = e.idespecialidade;

-- VIEW: vw_detalhes_avaliacoes
CREATE OR REPLACE VIEW `vw_detalhes_avaliacoes` AS
SELECT 
  consulta.id_consulta,
  consulta.data AS data_consulta,
  consulta.nome_paciente AS autor_avaliacao,
  consulta.nome_profissional AS profissional_avaliado,
  consulta.especialidade_profissional,
  a.nota,
  a.comentario,
  a.data_avaliacao
FROM avaliacoes a
JOIN vw_detalhes_consultas consulta ON a.consultas_idconsultas = consulta.id_consulta;

-- TRIGGER: Atualiza disponibilidade após agendamento
DELIMITER $$
CREATE TRIGGER `trg_atualiza_disponibilidade_apos_agendamento`
AFTER INSERT ON `consultas`
FOR EACH ROW
BEGIN
    UPDATE `disponibilidade`
    SET `disponivel` = 0
    WHERE 
        `profissionais_idprofissionais` = NEW.profissionais_idprofissionais
        AND `data` = NEW.data
        AND `hora` = NEW.hora;
END$$
DELIMITER ;

-- Continuação: Procedures, Views, Triggers, Inserts e Roles adaptados para o schema ConsultaMedica

USE `ConsultaMedica`;

INSERT INTO `especialidade` (`idespecialidade`, `nome`) VALUES
(1, 'Cardiologia'),
(2, 'Dermatologia'),
(3, 'Ginecologia e Obstetrícia'),
(4, 'Ortopedia e Traumatologia'),
(5, 'Pediatria'),
(6, 'Psiquiatria'),
(7, 'Urologia'),
(8, 'Oftalmologia'),
(9, 'Endocrinologia'),
(10, 'Neurologia');
-- PROCEDURES...
INSERT INTO `usuarios` (`idusuarios`, `nome`, `celular`, `email`, `data_de_nascimento`) VALUES
(1, 'Ana Clara Souza', '11987654321', 'ana.clara@email.com', '1995-03-15'),
(2, 'Bruno Carvalho', '21912345678', 'bruno.carvalho@email.com', '1988-11-20'),
(3, 'Carla Dias', '31988887777', 'carla.dias@email.com', '2001-07-02'),
(4, 'Daniel Ferreira', '41999998888', 'daniel.ferreira@email.com', '1990-01-30'),
(5, 'Elisa Gomes', '51987651234', 'elisa.gomes@email.com', '1992-05-25'),
(6, 'Fábio Martins', '61911112222', 'fabio.martins@email.com', '1985-09-10'),
(7, 'Gabriela Lima', '71933334444', 'gabriela.lima@email.com', '1998-12-01'),
(8, 'Heitor Barbosa', '81955556666', 'heitor.barbosa@email.com', '1979-04-18'),
(9, 'Isabela Rocha', '91977778888', 'isabela.rocha@email.com', '2003-02-22');
INSERT INTO `profissionais` (`idprofissionais`, `nome`, `celular`, `email`, `numero_licenca`, `biografia`, `aceita_convenio`, `especialidade_idespecialidade`) VALUES
(1, 'Dr. Ricardo Alves', '11912345678', 'ricardo.alves@med.com', 'CRM-SP 123456', 'Cardiologista com 15 anos de experiência em hospitais de referência.', 1, 1),
(2, 'Dra. Luiza Campos', '21987654321', 'luiza.campos@med.com', 'CRM-RJ 234567', 'Especialista em dermatologia clínica e estética.', 0, 2),
(3, 'Dra. Sofia Pereira', '31998765432', 'sofia.pereira@med.com', 'CRM-MG 345678', 'Ginecologista dedicada à saúde da mulher em todas as fases da vida.', 1, 3),
(4, 'Dr. Marcos Andrade', '41987651111', 'marcos.andrade@med.com', 'CRM-PR 456789', 'Ortopedista especializado em cirurgias do joelho e medicina esportiva.', 1, 4),
(5, 'Dra. Beatriz Costa', '51911223344', 'beatriz.costa@med.com', 'CRM-RS 567890', 'Pediatra apaixonada por acompanhar o desenvolvimento infantil.', 0, 5),
(6, 'Dr. Jorge Mendes', '61955667788', 'jorge.mendes@med.com', 'CRM-DF 678901', 'Psiquiatra com foco em terapia cognitivo-comportamental.', 1, 6),
(7, 'Dr. Vinicius Barros', '71999887766', 'vinicius.barros@med.com', 'CRM-BA 789012', 'Urologista com vasta experiência em saúde masculina.', 1, 7),
(8, 'Dra. Helena Ribeiro', '81911119999', 'helena.ribeiro@med.com', 'CRM-PE 890123', 'Oftalmologista especialista em cirurgia refrativa e catarata.', 0, 8),
(9, 'Dra. Fernanda Azevedo', '91922223333', 'fernanda.azevedo@med.com', 'CRM-PA 901234', 'Endocrinologista focada em distúrbios da tireoide e diabetes.', 1, 9);

INSERT INTO `disponibilidade` (`iddisponibilidade`, `hora`, `data`, `disponivel`, `profissionais_idprofissionais`) VALUES
(1, '09:00:00', '2025-07-20', 1, 1),
(2, '10:00:00', '2025-07-21', 1, 1),
(3, '14:00:00', '2025-07-22', 1, 2),
(4, '15:00:00', '2025-07-23', 1, 2),
(5, '08:30:00', '2025-07-24', 1, 3),
(6, '09:30:00', '2025-07-25', 1, 3),
(7, '11:00:00', '2025-07-26', 1, 4),
(8, '13:00:00', '2025-07-27', 1, 4),
(9, '16:00:00', '2025-07-28', 1, 5),
(10, '17:00:00', '2025-07-29', 1, 5),
(11, '10:00:00', '2025-07-30', 1, 6),
(12, '11:00:00', '2025-07-31', 1, 6),
(13, '09:00:00', '2025-08-01', 1, 7),
(14, '10:00:00', '2025-08-02', 1, 7),
(15, '14:30:00', '2025-08-03', 1, 8),
(16, '15:30:00', '2025-08-04', 1, 8),
(17, '08:00:00', '2025-08-05', 1, 9),
(18, '09:00:00', '2025-08-06', 1, 9);

-- Dr. Ricardo (ID 1)
CALL sp_agendar_consulta(1, 1, '2025-07-20', '09:00:00', 'Check-up cardiológico anual.');
CALL sp_agendar_consulta(2, 1, '2025-07-21', '10:00:00', 'Consulta de retorno para mostrar exames.');

-- Dra. Luiza (ID 2)
CALL sp_agendar_consulta(3, 2, '2025-07-22', '14:00:00', 'Consulta para avaliação de mancha na pele.');
CALL sp_agendar_consulta(4, 2, '2025-07-23', '15:00:00', 'Vacinação e acompanhamento.');

-- Dra. Sofia (ID 3)
CALL sp_agendar_consulta(5, 3, '2025-07-24', '08:30:00', 'Rotina ginecológica.');
CALL sp_agendar_consulta(6, 3, '2025-07-25', '09:30:00', 'Retorno de exames preventivos.');

-- Dr. Marcos (ID 4)
CALL sp_agendar_consulta(7, 4, '2025-07-26', '11:00:00', 'Paciente com dor no joelho direito após esporte.');
CALL sp_agendar_consulta(8, 4, '2025-07-27', '13:00:00', 'Revisão ortopédica.');

-- Dra. Beatriz (ID 5)
CALL sp_agendar_consulta(9, 5, '2025-07-28', '16:00:00', 'Paciente cancelou por motivo de viagem.');
CALL sp_agendar_consulta(1, 5, '2025-07-29', '17:00:00', 'Agendamento remarcado.');

-- Dr. Jorge (ID 6)
CALL sp_agendar_consulta(2, 6, '2025-07-30', '10:00:00', 'Primeira consulta de acompanhamento psiquiátrico.');
CALL sp_agendar_consulta(3, 6, '2025-07-31', '11:00:00', 'Retorno com prescrição.');

-- Dr. Vinicius (ID 7)
CALL sp_agendar_consulta(4, 7, '2025-08-01', '09:00:00', 'Exames de rotina urológica.');
CALL sp_agendar_consulta(5, 7, '2025-08-02', '10:00:00', 'Queixas urinárias frequentes.');

-- Dra. Helena (ID 8)
CALL sp_agendar_consulta(6, 8, '2025-08-03', '14:30:00', 'Paciente relata dificuldade para enxergar de longe.');
CALL sp_agendar_consulta(7, 8, '2025-08-04', '15:30:00', 'Retorno com resultado de exame de vista.');

-- Dra. Fernanda (ID 9)
CALL sp_agendar_consulta(8, 9, '2025-08-05', '08:00:00', 'Acompanhamento de diabetes.');
CALL sp_agendar_consulta(9, 9, '2025-08-06', '09:00:00', 'Exame de rotina geral.');

INSERT INTO `avaliacoes` ( `nota`, `comentario`, `data_avaliacao`, `consultas_idconsultas`) VALUES
( 5, 'Dr. Ricardo foi muito atencioso e explicou tudo com clareza.', '2025-06-11', 12),
( 5, 'Excelente profissional, resolveu meu problema de pele rapidamente.', '2025-06-12', 11),
( 4, 'A consulta foi boa, mas a clínica estava um pouco cheia.', '2025-06-13', 13),
( 5, 'Diagnóstico preciso e tratamento eficaz. Recomendo!', '2025-06-14', 14),
( 5, 'Dr. Jorge é um médico muito empático e me senti muito à vontade.', '2025-06-16', 16),
( 4, 'Bom atendimento, apenas demorou um pouco para ser chamado.', '2025-06-17', 17),
( 5, 'Dra. Helena é maravilhosa! Muito competente.', '2025-06-18', 18),
( 5, 'Muito satisfeita com o acompanhamento e os resultados.', '2025-06-19', 19),
( 5, 'Profissional exemplar.', '2025-06-19', 19);

-- Demais INSERTS e CALLs foram inseridos conforme o padrão já informado
-- Roles e usuários conforme abaixo:

CREATE ROLE IF NOT EXISTS 
  'role_paciente', 
  'role_profissional', 
  'role_administrativo';

GRANT SELECT ON ConsultaMedica.usuarios TO 'role_paciente';
GRANT SELECT, UPDATE ON ConsultaMedica.profissionais TO 'role_paciente';
GRANT SELECT ON ConsultaMedica.especialidade TO 'role_paciente';
GRANT SELECT, UPDATE, INSERT, DELETE ON ConsultaMedica.disponibilidade TO 'role_paciente';
GRANT INSERT, SELECT, UPDATE ON ConsultaMedica.consultas TO 'role_paciente';
GRANT INSERT, SELECT ON ConsultaMedica.avaliacoes TO 'role_paciente';

GRANT SELECT, INSERT, UPDATE ON ConsultaMedica.usuarios TO 'role_administrativo';
GRANT SELECT, INSERT, UPDATE ON ConsultaMedica.profissionais TO 'role_administrativo';
GRANT SELECT, INSERT, UPDATE, DELETE ON ConsultaMedica.disponibilidade TO 'role_administrativo';
GRANT SELECT, INSERT, UPDATE ON ConsultaMedica.consultas TO 'role_administrativo';
GRANT SELECT ON ConsultaMedica.avaliacoes TO 'role_administrativo';
GRANT SELECT, INSERT, UPDATE ON ConsultaMedica.especialidade TO 'role_administrativo';

GRANT SELECT ON ConsultaMedica.usuarios TO 'role_profissional';
GRANT SELECT, UPDATE ON ConsultaMedica.profissionais TO 'role_profissional';
GRANT SELECT ON ConsultaMedica.especialidade TO 'role_profissional';
GRANT SELECT, UPDATE, INSERT, DELETE ON ConsultaMedica.disponibilidade TO 'role_profissional';
GRANT INSERT, SELECT, UPDATE ON ConsultaMedica.consultas TO 'role_profissional';
GRANT INSERT, SELECT ON ConsultaMedica.avaliacoes TO 'role_profissional';

CREATE USER IF NOT EXISTS 'paciente_exemplo'@'localhost' IDENTIFIED BY 'SENHA_PACIENTE';
CREATE USER IF NOT EXISTS 'admin_clinica'@'localhost' IDENTIFIED BY 'SENHA_ADM';
CREATE USER IF NOT EXISTS 'medico_exemplo'@'localhost' IDENTIFIED BY 'SENHA_PROFISSIONAL';

GRANT 'role_paciente' TO 'paciente_exemplo'@'localhost';
GRANT 'role_administrativo' TO 'admin_clinica'@'localhost';
GRANT 'role_profissional' TO 'medico_exemplo'@'localhost';

SET DEFAULT ROLE ALL TO 
  'paciente_exemplo'@'localhost', 
  'admin_clinica'@'localhost',
  'medico_exemplo'@'localhost';
