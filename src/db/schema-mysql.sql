-- =====================================================================
-- Portal Escolar Acadêmico — schema MySQL (8.0.16+)
--
-- Equivalente ao schema-sqlite.sql (que é o banco usado pelo servidor).
-- Mantenha os dois arquivos com as mesmas tabelas, colunas e regras.
--
-- Uso: mysql -u root -p < src/db/schema-mysql.sql
-- =====================================================================

CREATE DATABASE IF NOT EXISTS portal_escolar
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE portal_escolar;

CREATE TABLE IF NOT EXISTS usuarios (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nome VARCHAR(120) NOT NULL,
  matricula VARCHAR(30) NOT NULL UNIQUE,
  email VARCHAR(150) NOT NULL UNIQUE,
  senha VARCHAR(255) NOT NULL,
  tipo ENUM('aluno','professor','admin') NOT NULL DEFAULT 'aluno',
  telefone VARCHAR(20) DEFAULT '',
  curso VARCHAR(100) DEFAULT 'Ensino Médio',
  turma VARCHAR(30) DEFAULT '',
  disciplina VARCHAR(100) DEFAULT '',
  criado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  atualizado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS notas (
  id INT AUTO_INCREMENT PRIMARY KEY,
  aluno_id INT NOT NULL,
  disciplina VARCHAR(100) NOT NULL,
  etapa VARCHAR(50) NOT NULL,
  nota DECIMAL(4,2) NOT NULL CHECK (nota >= 0 AND nota <= 10),
  criado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (aluno_id) REFERENCES usuarios(id) ON DELETE CASCADE,
  UNIQUE (aluno_id, disciplina, etapa),
  INDEX idx_notas_aluno (aluno_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS faltas (
  id INT AUTO_INCREMENT PRIMARY KEY,
  aluno_id INT NOT NULL,
  disciplina VARCHAR(100) NOT NULL,
  total_aulas INT NOT NULL CHECK (total_aulas > 0),
  faltas INT NOT NULL DEFAULT 0,
  CHECK (faltas >= 0 AND faltas <= total_aulas),
  FOREIGN KEY (aluno_id) REFERENCES usuarios(id) ON DELETE CASCADE,
  UNIQUE (aluno_id, disciplina),
  INDEX idx_faltas_aluno (aluno_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS disponibilidades (
  id INT AUTO_INCREMENT PRIMARY KEY,
  professor_id INT NOT NULL,
  data DATE NOT NULL,
  hora_inicio CHAR(5) NOT NULL,
  hora_fim CHAR(5) NOT NULL,
  local VARCHAR(100) NOT NULL DEFAULT 'Sala de Atendimento',
  status ENUM('disponivel','indisponivel') NOT NULL DEFAULT 'disponivel',
  FOREIGN KEY (professor_id) REFERENCES usuarios(id) ON DELETE CASCADE,
  INDEX idx_disp_data (data)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS agendamentos (
  id INT AUTO_INCREMENT PRIMARY KEY,
  aluno_id INT NOT NULL,
  disponibilidade_id INT NOT NULL,
  assunto VARCHAR(200) NOT NULL,
  observacao TEXT,
  status ENUM('agendado','cancelado','realizado') NOT NULL DEFAULT 'agendado',
  criado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (aluno_id) REFERENCES usuarios(id) ON DELETE CASCADE,
  FOREIGN KEY (disponibilidade_id) REFERENCES disponibilidades(id) ON DELETE CASCADE,
  INDEX idx_ag_aluno (aluno_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS recuperacao_senha (
  id INT AUTO_INCREMENT PRIMARY KEY,
  usuario_id INT NOT NULL,
  token_hash CHAR(64) NOT NULL UNIQUE,
  expira_em BIGINT NOT NULL,
  criado_em BIGINT NOT NULL DEFAULT (UNIX_TIMESTAMP() * 1000),
  FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Registro de todos os e-mails cadastrados no sistema.
CREATE TABLE IF NOT EXISTS emails_cadastrados (
  id INT AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(150) NOT NULL UNIQUE,
  usuario_id INT NULL,
  nome VARCHAR(120) NOT NULL DEFAULT '',
  tipo ENUM('aluno','professor','admin') NOT NULL DEFAULT 'aluno',
  cadastrado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE SET NULL,
  INDEX idx_emails_tipo (tipo)
) ENGINE=InnoDB;

DROP TRIGGER IF EXISTS trg_usuarios_email_insert;
DROP TRIGGER IF EXISTS trg_usuarios_email_update;

DELIMITER $$

CREATE TRIGGER trg_usuarios_email_insert
AFTER INSERT ON usuarios
FOR EACH ROW
BEGIN
  INSERT IGNORE INTO emails_cadastrados(email, usuario_id, nome, tipo)
  VALUES (LOWER(NEW.email), NEW.id, NEW.nome, NEW.tipo);
END$$

CREATE TRIGGER trg_usuarios_email_update
AFTER UPDATE ON usuarios
FOR EACH ROW
BEGIN
  IF NOT (NEW.email <=> OLD.email AND NEW.nome <=> OLD.nome AND NEW.tipo <=> OLD.tipo) THEN
    INSERT IGNORE INTO emails_cadastrados(email, usuario_id, nome, tipo)
    VALUES (LOWER(NEW.email), NEW.id, NEW.nome, NEW.tipo);
    UPDATE emails_cadastrados SET nome = NEW.nome, tipo = NEW.tipo
    WHERE email = LOWER(NEW.email);
  END IF;
END$$

DELIMITER ;

-- Copia e-mails de usuários que já existiam antes da tabela emails_cadastrados.
INSERT IGNORE INTO emails_cadastrados(email, usuario_id, nome, tipo, cadastrado_em)
SELECT LOWER(email), id, nome, tipo, criado_em FROM usuarios;
