sql
CREATE DATABASE IF NOT EXISTS academia;
USE academia;

CREATE TABLE alunos (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    nome          VARCHAR(100) NOT NULL,
    email         VARCHAR(120) NOT NULL UNIQUE,
    cpf           CHAR(11)     NOT NULL UNIQUE,
    telefone      VARCHAR(20)  NOT NULL,
    data_cadastro DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE planos (
    id                INT AUTO_INCREMENT PRIMARY KEY,
    nome              VARCHAR(60)   NOT NULL UNIQUE,
    valor_mensal_base DECIMAL(10,2) NOT NULL,
    CONSTRAINT ck_planos_valor CHECK (valor_mensal_base > 0)
);

CREATE TABLE modalidades (
    id                INT AUTO_INCREMENT PRIMARY KEY,
    plano_id          INT          NOT NULL,
    nome              VARCHAR(80)  NOT NULL,
    sala              VARCHAR(40)  NOT NULL,
    capacidade_maxima INT          NOT NULL,
    disponivel        BOOLEAN      NOT NULL DEFAULT TRUE,
    CONSTRAINT fk_modalidades_plano FOREIGN KEY (plano_id) REFERENCES planos(id),
    CONSTRAINT ck_modalidades_cap CHECK (capacidade_maxima > 0)
);

CREATE TABLE matriculas (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    aluno_id    INT         NOT NULL,
    data_inicio DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status      VARCHAR(10) NOT NULL DEFAULT 'Ativa',
    CONSTRAINT fk_matriculas_aluno FOREIGN KEY (aluno_id) REFERENCES alunos(id),
    CONSTRAINT ck_matriculas_status CHECK (status IN ('Ativa', 'Cancelada', 'Trancada'))
);

CREATE TABLE itens_matricula (
    id                    INT AUTO_INCREMENT PRIMARY KEY,
    matricula_id          INT           NOT NULL,
    modalidade_id         INT           NOT NULL,
    duracao_meses         INT           NOT NULL,
    valor_mensal_aplicado DECIMAL(10,2) NOT NULL,
    taxa_adesao           DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    CONSTRAINT fk_itens_matricula  FOREIGN KEY (matricula_id)  REFERENCES matriculas(id),
    CONSTRAINT fk_itens_modalidade FOREIGN KEY (modalidade_id) REFERENCES modalidades(id),
    CONSTRAINT ck_itens_duracao CHECK (duracao_meses > 0),
    CONSTRAINT ck_itens_valor   CHECK (valor_mensal_aplicado > 0),
    CONSTRAINT ck_itens_taxa    CHECK (taxa_adesao >= 0)
);

sql
INSERT INTO planos (nome, valor_mensal_base) VALUES
('VIP Premium',      250.00),
('Fitness Standard', 150.00),
('Basic Fit',         90.00);

INSERT INTO modalidades (plano_id, nome, sala, capacidade_maxima, disponivel) VALUES
(1, 'Crossfit Pro',      'Arena 01',  20, TRUE),
(2, 'Pilates Avançado',  'Studio 02', 15, TRUE),
(3, 'Musculação Livre',  'Sala 03',   40, TRUE);

INSERT INTO alunos (nome, email, cpf, telefone) VALUES
('Ana Souza',    'ana.souza@email.com',    '11111111111', '48999990001'),
('Bruno Lima',   'bruno.lima@email.com',   '22222222222', '48999990002'),
('Carla Mendes', 'carla.mendes@email.com', '33333333333', '48999990003');

INSERT INTO matriculas (aluno_id, data_inicio, status) VALUES
(1, '2026-01-10 08:00:00', 'Ativa'),
(1, '2026-03-05 09:30:00', 'Ativa'),
(2, '2026-02-15 18:00:00', 'Ativa'),
(3, '2026-04-01 07:00:00', 'Cancelada');

INSERT INTO itens_matricula (matricula_id, modalidade_id, duracao_meses, valor_mensal_aplicado, taxa_adesao) VALUES
(1, 1, 12, 275.00, 50.00),
(2, 2,  6, 165.00,  0.00),
(3, 3,  6,  99.00, 30.00),
(4, 1,  3, 275.00, 50.00);




sql
CREATE VIEW vw_modalidades_custo_estimado AS
SELECT m.nome AS modalidade,
       m.sala,
       p.nome AS plano,
       ROUND(p.valor_mensal_base * 1.10, 2) AS valor_mensal_ajustado
FROM modalidades m
JOIN planos p ON p.id = m.plano_id
ORDER BY valor_mensal_ajustado DESC;



sql
CREATE VIEW vw_matriculas_ativas AS
SELECT a.nome AS aluno,
       a.cpf,
       m.nome AS modalidade,
       m.sala,
       i.duracao_meses,
       mt.data_inicio
FROM matriculas mt
JOIN alunos a          ON a.id  = mt.aluno_id
JOIN itens_matricula i ON i.matricula_id = mt.id
JOIN modalidades m     ON m.id  = i.modalidade_id
WHERE mt.status = 'Ativa';



sql
CREATE VIEW vw_alunos_vip AS
SELECT a.nome AS aluno,
       COUNT(i.id) AS qtd_contratos_ativos,
       SUM(i.valor_mensal_aplicado * i.duracao_meses + i.taxa_adesao) AS valor_total_investido
FROM alunos a
JOIN matriculas mt     ON mt.aluno_id = a.id
JOIN itens_matricula i ON i.matricula_id = mt.id
WHERE mt.status = 'Ativa'
GROUP BY a.id, a.nome
HAVING SUM(i.valor_mensal_aplicado * i.duracao_meses + i.taxa_adesao) > 1000;



sql
SELECT m.id, m.nome, m.sala, m.capacidade_maxima, p.nome AS plano, p.valor_mensal_base
FROM modalidades m
JOIN planos p ON p.id = m.plano_id
WHERE m.capacidade_maxima >= 15
  AND p.valor_mensal_base > 100
  AND m.disponivel = TRUE;



sql
CREATE VIEW vw_faturamento_medio_plano AS
SELECT p.nome AS plano,
       SUM(i.valor_mensal_aplicado * i.duracao_meses + i.taxa_adesao) AS faturamento_total,
       AVG(i.duracao_meses) AS media_duracao_meses
FROM planos p
JOIN modalidades m     ON m.plano_id = p.id
JOIN itens_matricula i ON i.modalidade_id = m.id
JOIN matriculas mt     ON mt.id = i.matricula_id
WHERE mt.status = 'Ativa'
GROUP BY p.id, p.nome;