# 🏥 Banco de Dados ConsultaMedica (MySQL)

Este projeto consiste no banco de dados **ConsultaMedica**, desenvolvido em **MySQL** para gerenciar o processo voluntário de agendamento, cancelamento e conclusão de consultas médicas, além do controle de profissionais, pacientes, especialidades, avaliações e disponibilidade dos profissionais.

---

## 📑 Índice

- [� Banco de Dados ConsultaMedica (MySQL)](#-banco-de-dados-consultamedica-mysql)
  - [📑 Índice](#-índice)
  - [🏗️ Estrutura do Banco](#️-estrutura-do-banco)
    - [📋 Principais Tabelas](#-principais-tabelas)
    - [🔗 Relacionamentos](#-relacionamentos)
  - [⚙️ Procedures (Procedimentos Armazenados)](#️-procedures-procedimentos-armazenados)
    - [1. `sp_agendar_consulta` 📆](#1-sp_agendar_consulta-)
    - [2. `cancelar_consulta` ❌](#2-cancelar_consulta-)
    - [3. `concluir_consulta` ✔️](#3-concluir_consulta-️)
  - [🔍 Views (Visões)](#-views-visões)
    - [1. `vw_detalhes_consultas` 📋](#1-vw_detalhes_consultas-)
    - [2. `vw_detalhes_avaliacoes` ⭐](#2-vw_detalhes_avaliacoes-)
  - [⏰ Triggers (Gatilhos)](#-triggers-gatilhos)
    - [`trg_atualiza_disponibilidade_apos_agendamento` 🔄](#trg_atualiza_disponibilidade_apos_agendamento-)
  - [❗ Tratamento de Erros com SIGNAL](#-tratamento-de-erros-com-signal)
  - [🛡️ Roles e Permissões](#️-roles-e-permissões)
  - [👥 Usuários de Exemplo](#-usuários-de-exemplo)
  - [📥 Inserções de Dados de Teste](#-inserções-de-dados-de-teste)
  - [🚀 Como Utilizar](#-como-utilizar)
  - [📝 Considerações Finais](#-considerações-finais)

---

## 🏗️ Estrutura do Banco

### 📋 Principais Tabelas

- **especialidade**: Armazena as especialidades médicas 🩺.
- **profissionais**: Contém dados dos profissionais de saúde, com vínculo para especialidade 👩‍⚕️👨‍⚕️.
- **usuarios**: Registra os pacientes (usuários) 🧑‍🤝‍🧑.
- **consultas**: Registra as consultas agendadas, com referência ao paciente e profissional 📅.
- **avaliacoes**: Armazena avaliações feitas pelos pacientes sobre as consultas ⭐.
- **disponibilidade**: Controla os horários disponíveis de cada profissional ⏰.

### 🔗 Relacionamentos

- Cada profissional tem uma especialidade (FK para `especialidade`).
- Cada consulta relaciona um paciente (`usuarios`) com um profissional (`profissionais`).
- Avaliações estão ligadas a uma consulta específica.
- A disponibilidade é vinculada a profissionais e controla horários que podem ser agendados.

---

## ⚙️ Procedures (Procedimentos Armazenados)

### 1. `sp_agendar_consulta` 📆

Agendamento de consultas com verificação de disponibilidade.

- Verifica se o horário está disponível na tabela `disponibilidade`.
- Se indisponível ou inexistente, retorna erro via `SIGNAL` ❌.
- Caso positivo, insere a consulta com status `agendada` ✅.

### 2. `cancelar_consulta` ❌

- Altera o status da consulta para `cancelada`.
- Libera o horário na tabela `disponibilidade` 🕒.
- Valida se a consulta existe e se ainda não está cancelada.

### 3. `concluir_consulta` ✔️

- Marca a consulta como `concluida`.
- Adiciona novas observações concatenando com as anteriores 📝.
- Libera o horário na disponibilidade.
- Verifica se a consulta existe, não está cancelada ou concluída anteriormente.

---

## 🔍 Views (Visões)

### 1. `vw_detalhes_consultas` 📋

Apresenta uma visão consolidada das consultas, unindo informações de pacientes, profissionais e especialidades.

### 2. `vw_detalhes_avaliacoes` ⭐

Exibe avaliações detalhadas relacionadas às consultas, incluindo dados do paciente e profissional avaliado.

---

## ⏰ Triggers (Gatilhos)

### `trg_atualiza_disponibilidade_apos_agendamento` 🔄

- Após uma consulta ser inserida (`INSERT`), atualiza a disponibilidade do profissional naquele horário para indisponível (`disponivel = 0`).

---

## ❗ Tratamento de Erros com SIGNAL

O banco utiliza a instrução `SIGNAL SQLSTATE '45000'` para lançar erros customizados em procedimentos quando:

- Horário solicitado não existe 🕒.
- Horário já está ocupado ⛔.
- Consulta não encontrada ❓.
- Consulta já cancelada ou concluída ⚠️.

Isso melhora o controle e feedback na aplicação que consumir o banco.

---

## 🛡️ Roles e Permissões

Foram criadas 3 roles para controle de acesso:

| Role             | Descrição                         | Permissões principais                                         |
|------------------|---------------------------------|---------------------------------------------------------------|
| `role_paciente`      | Usuário paciente 🧑‍⚕️          | Consultas, avaliações, visualizar profissionais e especialidades, gerenciar disponibilidade própria. |
| `role_profissional`  | Médico / Profissional 👩‍⚕️      | Gerenciar consultas, disponibilidade, avaliações; consultar pacientes e especialidades.             |
| `role_administrativo`| Administrativo / Admin 🧑‍💼     | Controle total em usuários, profissionais, consultas, especialidades, avaliações e disponibilidade. |

As permissões são aplicadas com `GRANT` para garantir acesso adequado e seguro 🔐.

---

## 👥 Usuários de Exemplo

- `paciente_exemplo` — Role: `role_paciente`
- `medico_exemplo` — Role: `role_profissional`
- `admin_clinica` — Role: `role_administrativo`

Cada usuário tem sua senha e acesso conforme as roles definidas.

---

## 📥 Inserções de Dados de Teste

- Pacientes, profissionais, especialidades, disponibilidades e avaliações foram inseridos para testes práticos e demonstração das funcionalidades do banco.

---

## 🚀 Como Utilizar

1. Crie o schema `ConsultaMedica` 🏗️.
2. Crie as tabelas, procedures, views, triggers e roles conforme o script 📜.
3. Insira os dados de teste para simular o ambiente 🎯.
4. Utilize as procedures para agendar, cancelar e concluir consultas 📅.
5. Consulte as views para obter relatórios detalhados 📊.
6. Aplique as roles nos usuários para garantir segurança e controle de acesso 🔐.

---

## 📝 Considerações Finais

Este banco de dados foi desenhado em **MySQL** para facilitar a gestão clínica, garantindo integridade, segurança e facilidade no controle de agendas e avaliações, com tratamento de erros robusto via `SIGNAL` e controle de permissões via roles.

---

**Desenvolvido por:** Vitor Hugo Weber Barbosa  
**Data:** Julho 2025
