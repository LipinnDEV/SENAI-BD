-- =============================================================================
-- DESAFIO DE BANCO DE DADOS — CLÍNICA VETERINÁRIA
-- Aluno: Felipe Da Silva Mousinho
-- Arquivo: clinica_veterinaria.sql
-- =============================================================================


-- =============================================================================
-- 1. CRIAÇÃO DO BANCO DE DADOS
-- =============================================================================

DROP DATABASE IF EXISTS clinica_veterinaria;

CREATE DATABASE clinica_veterinaria
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE clinica_veterinaria;

SET NAMES utf8mb4;


-- =============================================================================
-- 2. CRIAÇÃO DAS TABELAS E RESTRIÇÕES
-- =============================================================================

-- Tabela: categoria
CREATE TABLE categoria (
    id_categoria INT NOT NULL AUTO_INCREMENT,
    nome VARCHAR(60) NOT NULL,
    descricao VARCHAR(255),
    PRIMARY KEY (id_categoria),
    CONSTRAINT uq_categoria_nome UNIQUE (nome)
) ENGINE = InnoDB;

-- Tabela: tutor
CREATE TABLE tutor (
    id_tutor INT NOT NULL AUTO_INCREMENT,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(120) NOT NULL,
    telefone VARCHAR(20) NOT NULL,
    cidade VARCHAR(60) NOT NULL,
    PRIMARY KEY (id_tutor),
    CONSTRAINT uq_tutor_email UNIQUE (email),
    CONSTRAINT chk_tutor_email CHECK (email LIKE '%_@_%')
) ENGINE = InnoDB;

-- Tabela: animal
CREATE TABLE animal (
    id_animal INT NOT NULL AUTO_INCREMENT,
    nome VARCHAR(60) NOT NULL,
    especie VARCHAR(40) NOT NULL,
    raca VARCHAR(60),
    data_nascimento DATE,
    id_tutor INT NOT NULL,
    PRIMARY KEY (id_animal),
    CONSTRAINT fk_animal_tutor FOREIGN KEY (id_tutor)
        REFERENCES tutor (id_tutor)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB;

-- Tabela: veterinario
CREATE TABLE veterinario (
    id_veterinario INT NOT NULL AUTO_INCREMENT,
    nome VARCHAR(100) NOT NULL,
    crmv VARCHAR(20) NOT NULL,
    especialidade VARCHAR(60) NOT NULL,
    email VARCHAR(120) NOT NULL,
    PRIMARY KEY (id_veterinario),
    CONSTRAINT uq_veterinario_crmv UNIQUE (crmv),
    CONSTRAINT uq_veterinario_email UNIQUE (email)
) ENGINE = InnoDB;

-- Tabela: servico
CREATE TABLE servico (
    id_servico INT NOT NULL AUTO_INCREMENT,
    nome VARCHAR(80) NOT NULL,
    descricao VARCHAR(255),
    preco DECIMAL(10,2) NOT NULL,
    id_categoria INT NOT NULL,
    PRIMARY KEY (id_servico),
    CONSTRAINT uq_servico_nome UNIQUE (nome),
    CONSTRAINT chk_servico_preco CHECK (preco >= 0),
    CONSTRAINT fk_servico_categoria FOREIGN KEY (id_categoria)
        REFERENCES categoria (id_categoria)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB;

-- Tabela: consulta
CREATE TABLE consulta (
    id_consulta INT NOT NULL AUTO_INCREMENT,
    data_hora DATETIME NOT NULL,
    motivo VARCHAR(255) NOT NULL,
    diagnostico VARCHAR(255),
    status ENUM('AGENDADA','REALIZADA','CANCELADA','FALTOU') NOT NULL DEFAULT 'AGENDADA',
    id_animal INT NOT NULL,
    id_veterinario INT NOT NULL,
    PRIMARY KEY (id_consulta),
    CONSTRAINT uq_consulta_veterinario_horario UNIQUE (id_veterinario, data_hora),
    CONSTRAINT fk_consulta_animal FOREIGN KEY (id_animal)
        REFERENCES animal (id_animal)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_consulta_veterinario FOREIGN KEY (id_veterinario)
        REFERENCES veterinario (id_veterinario)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB;

-- Tabela: item_consulta
CREATE TABLE item_consulta (
    id_item_consulta INT NOT NULL AUTO_INCREMENT,
    quantidade INT NOT NULL DEFAULT 1,
    preco_unitario DECIMAL(10,2) NOT NULL,
    id_consulta INT NOT NULL,
    id_servico INT NOT NULL,
    PRIMARY KEY (id_item_consulta),
    CONSTRAINT uq_item_consulta_servico UNIQUE (id_consulta, id_servico),
    CONSTRAINT chk_item_consulta_quantidade CHECK (quantidade > 0),
    CONSTRAINT chk_item_consulta_preco CHECK (preco_unitario >= 0),
    CONSTRAINT fk_item_consulta_consulta FOREIGN KEY (id_consulta)
        REFERENCES consulta (id_consulta)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_item_consulta_servico FOREIGN KEY (id_servico)
        REFERENCES servico (id_servico)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB;

-- Tabela: pagamento
CREATE TABLE pagamento (
    id_pagamento INT NOT NULL AUTO_INCREMENT,
    data_pagamento DATE NOT NULL,
    valor DECIMAL(10,2) NOT NULL,
    metodo ENUM('PIX','CARTAO','DINHEIRO') NOT NULL,
    status ENUM('PENDENTE','APROVADO','RECUSADO') NOT NULL DEFAULT 'PENDENTE',
    id_consulta INT NOT NULL,
    PRIMARY KEY (id_pagamento),
    CONSTRAINT chk_pagamento_valor CHECK (valor > 0),
    CONSTRAINT fk_pagamento_consulta FOREIGN KEY (id_consulta)
        REFERENCES consulta (id_consulta)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB;

-- Tabela: vacina
CREATE TABLE vacina (
    id_vacina INT NOT NULL AUTO_INCREMENT,
    nome VARCHAR(80) NOT NULL,
    fabricante VARCHAR(80) NOT NULL,
    descricao VARCHAR(255),
    PRIMARY KEY (id_vacina),
    CONSTRAINT uq_vacina_nome UNIQUE (nome)
) ENGINE = InnoDB;

-- Tabela: aplicacao_vacina
CREATE TABLE aplicacao_vacina (
    id_aplicacao INT NOT NULL AUTO_INCREMENT,
    data_aplicacao DATE NOT NULL,
    lote VARCHAR(30) NOT NULL,
    id_animal INT NOT NULL,
    id_vacina INT NOT NULL,
    id_veterinario INT NOT NULL,
    PRIMARY KEY (id_aplicacao),
    CONSTRAINT uq_aplicacao_animal_vacina_data UNIQUE (id_animal, id_vacina, data_aplicacao),
    CONSTRAINT fk_aplicacao_animal FOREIGN KEY (id_animal)
        REFERENCES animal (id_animal)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_aplicacao_vacina FOREIGN KEY (id_vacina)
        REFERENCES vacina (id_vacina)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_aplicacao_veterinario FOREIGN KEY (id_veterinario)
        REFERENCES veterinario (id_veterinario)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB;


-- =============================================================================
-- 3. INSERÇÃO DOS DADOS
-- =============================================================================

-- categoria (5)
INSERT INTO categoria (id_categoria, nome, descricao) VALUES
(1, 'Consulta', 'Consultas clínicas gerais e especializadas'),
(2, 'Exames', 'Exames laboratoriais e de imagem'),
(3, 'Procedimentos', 'Cirurgias e procedimentos ambulatoriais'),
(4, 'Vacinação', 'Aplicação de vacinas obrigatórias e opcionais'),
(5, 'Cuidados preventivos', 'Vermifugação, controle de parasitas e prevenção');

-- tutor (15)
INSERT INTO tutor (id_tutor, nome, email, telefone, cidade) VALUES
(1, 'Ana Paula Ribeiro', 'ana.ribeiro@example.com', '(47) 99999-0001', 'Blumenau'),
(2, 'Carlos Eduardo Menezes', 'carlos.menezes@example.com', '(47) 99999-0002', 'Gaspar'),
(3, 'Fernanda Lima Souza', 'fernanda.souza@example.com', '(47) 99999-0003', 'Indaial'),
(4, 'João Pedro Martins', 'joao.martins@example.com', '(47) 99999-0004', 'Blumenau'),
(5, 'Mariana Costa Alves', 'mariana.alves@example.com', '(47) 99999-0005', 'Pomerode'),
(6, 'Ricardo Teixeira', 'ricardo.teixeira@example.com', '(47) 99999-0006', 'Timbó'),
(7, 'Luciana Ferreira', 'luciana.ferreira@example.com', '(47) 99999-0007', 'Brusque'),
(8, 'Marcos Vinícius Duarte', 'marcos.duarte@example.com', '(47) 99999-0008', 'Blumenau'),
(9, 'Patrícia Nogueira', 'patricia.nogueira@example.com', '(47) 99999-0009', 'Joinville'),
(10, 'Rafael Almeida', 'rafael.almeida@example.com', '(48) 99999-0010', 'Florianópolis'),
(11, 'Juliana Santos', 'juliana.santos@example.com', '(47) 99999-0011', 'Blumenau'),
(12, 'Bruno Henrique Moraes', 'bruno.moraes@example.com', '(47) 99999-0012', 'Gaspar'),
(13, 'Camila Rocha', 'camila.rocha@example.com', '(47) 99999-0013', 'Indaial'),
(14, 'Diego Fernandes', 'diego.fernandes@example.com', '(41) 99999-0014', 'Curitiba'),
(15, 'Aline Cardoso', 'aline.cardoso@example.com', '(47) 99999-0015', 'Pomerode');

-- animal (20)
INSERT INTO animal (id_animal, nome, especie, raca, data_nascimento, id_tutor) VALUES
(1, 'Thor', 'Cachorro', 'Labrador', '2019-03-12', 1),
(2, 'Mel', 'Cachorro', 'Golden Retriever', '2020-07-25', 1),
(3, 'Luna', 'Gato', 'SRD', '2021-01-10', 2),
(4, 'Bob', 'Cachorro', 'Poodle', '2018-11-05', 3),
(5, 'Nina', 'Gato', 'Siamês', '2022-04-18', 4),
(6, 'Pipoca', 'Coelho', 'Mini Lop', '2023-02-14', 4),
(7, 'Max', 'Cachorro', 'Bulldog Francês', '2017-09-30', 5),
(8, 'Mia', 'Gato', 'Persa', '2020-12-02', 6),
(9, 'Zeca', 'Cachorro', 'SRD', '2016-05-21', 7),
(10, 'Princesa', 'Cachorro', 'Shih Tzu', '2021-08-09', 8),
(11, 'Simba', 'Gato', 'Maine Coon', '2022-10-27', 8),
(12, 'Frida', 'Cachorro', 'Dachshund', '2019-06-15', 9),
(13, 'Rex', 'Cachorro', 'Pastor Alemão', '2015-03-03', 10),
(14, 'Bidu', 'Cachorro', 'Beagle', '2026-03-10', 11),
(15, 'Mingau', 'Gato', 'SRD', '2024-05-11', 11),
(16, 'Fofão', 'Hamster', 'Sírio', '2025-02-08', 12),
(17, 'Kiwi', 'Ave', 'Calopsita', '2023-09-17', 12),
(18, 'Amora', 'Gato', 'Angorá', '2021-03-29', 13),
(19, 'Tobias', 'Cachorro', 'Border Collie', '2020-02-14', 13),
(20, 'Docinho', 'Coelho', 'Mini Rex', '2024-07-01', 13);

-- veterinario (6)
INSERT INTO veterinario (id_veterinario, nome, crmv, especialidade, email) VALUES
(1, 'Dra. Helena Carvalho', 'CRMV-SC 10234', 'Clínica Geral', 'helena.carvalho@example.com'),
(2, 'Dr. Paulo Ricardo Nunes', 'CRMV-SC 11876', 'Cirurgia', 'paulo.nunes@example.com'),
(3, 'Dra. Sofia Albuquerque', 'CRMV-SC 12455', 'Dermatologia', 'sofia.albuquerque@example.com'),
(4, 'Dr. Gustavo Prado', 'CRMV-SC 09981', 'Animais Silvestres e Exóticos', 'gustavo.prado@example.com'),
(5, 'Dra. Beatriz Fontana', 'CRMV-SC 13302', 'Cardiologia', 'beatriz.fontana@example.com'),
(6, 'Dr. André Lopes', 'CRMV-SC 12011', 'Ortopedia', 'andre.lopes@example.com');

-- servico (12)
INSERT INTO servico (id_servico, nome, descricao, preco, id_categoria) VALUES
(1, 'Consulta clínica geral', 'Avaliação clínica completa do animal', 120.00, 1),
(2, 'Consulta especializada', 'Consulta com veterinário especialista', 180.00, 1),
(3, 'Hemograma completo', 'Análise laboratorial do sangue', 95.00, 2),
(4, 'Ultrassonografia abdominal', 'Exame de imagem da região abdominal', 220.00, 2),
(5, 'Radiografia', 'Exame de raio-X por projeção', 160.00, 2),
(6, 'Castração', 'Cirurgia de esterilização com anestesia', 480.00, 3),
(7, 'Limpeza de tártaro', 'Profilaxia dentária com ultrassom', 280.00, 3),
(8, 'Curativo e sutura', 'Limpeza de ferimentos e pontos cirúrgicos', 90.00, 3),
(9, 'Aplicação de vacina polivalente', 'Dose de vacina V10 (cães) ou V4 (gatos)', 110.00, 4),
(10, 'Aplicação de vacina antirrábica', 'Dose anual contra a raiva', 85.00, 4),
(11, 'Vermifugação', 'Administração de vermífugo conforme o peso', 60.00, 5),
(12, 'Controle de pulgas e carrapatos', 'Aplicação de antiparasitário externo', 75.00, 5);

-- consulta (20)
INSERT INTO consulta (id_consulta, data_hora, motivo, diagnostico, status, id_animal, id_veterinario) VALUES
(1, '2026-07-06 09:00:00', 'Check-up anual', 'Animal saudável, peso adequado', 'REALIZADA', 1, 1),
(2, '2026-07-08 14:30:00', 'Vômitos e perda de apetite', 'Gastrite leve', 'REALIZADA', 3, 1),
(3, '2026-07-15 10:00:00', 'Coceira intensa e queda de pelo', 'Dermatite alérgica', 'REALIZADA', 4, 3),
(4, '2026-07-22 16:00:00', 'Castração eletiva', 'Procedimento realizado sem intercorrências', 'REALIZADA', 7, 2),
(5, '2026-08-03 11:00:00', 'Espirros e secreção nasal', 'Rinotraqueíte felina', 'REALIZADA', 8, 1),
(6, '2026-08-12 15:00:00', 'Claudicação na pata traseira', 'Displasia coxofemoral leve', 'REALIZADA', 13, 6),
(7, '2026-08-19 09:30:00', 'Vacinação e vermifugação', 'Animal apto, vacinas em dia', 'REALIZADA', 2, 1),
(8, '2026-08-26 10:30:00', 'Limpeza de tártaro', 'Tártaro grau 3, limpeza realizada', 'REALIZADA', 10, 2),
(9, '2026-09-02 14:00:00', 'Check-up e vacinação', 'Animal saudável', 'REALIZADA', 11, 1),
(10, '2026-09-09 08:30:00', 'Dor na coluna', 'Suspeita de hérnia de disco', 'REALIZADA', 12, 6),
(11, '2026-09-16 13:30:00', 'Primeira consulta de filhote', 'Filhote saudável, protocolo vacinal iniciado', 'REALIZADA', 14, 1),
(12, '2026-09-23 16:30:00', 'Queda de pelo e coceira', 'Alergia alimentar', 'REALIZADA', 18, 3),
(13, '2026-10-01 09:00:00', 'Vacinação anual', 'Animal apto, vacinas atualizadas', 'REALIZADA', 19, 1),
(14, '2026-10-08 11:30:00', 'Nódulo no flanco', 'Lipoma, acompanhamento recomendado', 'REALIZADA', 9, 2),
(15, '2026-10-20 10:00:00', 'Check-up de rotina', NULL, 'CANCELADA', 5, 1),
(16, '2026-10-22 15:00:00', 'Dentes crescidos', NULL, 'FALTOU', 6, 4),
(17, '2026-10-27 09:30:00', 'Apatia e penas arrepiadas', NULL, 'CANCELADA', 17, 4),
(18, '2026-11-12 14:00:00', 'Check-up de rotina', NULL, 'AGENDADA', 20, 4),
(19, '2026-11-18 09:00:00', 'Avaliação de peso e articulações', NULL, 'AGENDADA', 1, 6),
(20, '2026-11-25 16:00:00', 'Retorno dermatológico', NULL, 'AGENDADA', 4, 3);

-- item_consulta (37)
INSERT INTO item_consulta (id_item_consulta, quantidade, preco_unitario, id_consulta, id_servico) VALUES
(1, 1, 110.00, 1, 1),
(2, 1, 90.00, 1, 3),
(3, 1, 60.00, 1, 11),
(4, 1, 110.00, 2, 1),
(5, 1, 90.00, 2, 3),
(6, 1, 220.00, 2, 4),
(7, 1, 170.00, 3, 2),
(8, 1, 90.00, 3, 3),
(9, 1, 170.00, 4, 2),
(10, 1, 90.00, 4, 3),
(11, 1, 450.00, 4, 6),
(12, 1, 120.00, 5, 1),
(13, 1, 160.00, 5, 5),
(14, 1, 180.00, 6, 2),
(15, 2, 160.00, 6, 5),
(16, 1, 120.00, 7, 1),
(17, 1, 110.00, 7, 9),
(18, 1, 60.00, 7, 11),
(19, 1, 180.00, 8, 2),
(20, 1, 95.00, 8, 3),
(21, 1, 280.00, 8, 7),
(22, 1, 120.00, 9, 1),
(23, 1, 110.00, 9, 9),
(24, 1, 85.00, 9, 10),
(25, 1, 60.00, 9, 11),
(26, 1, 180.00, 10, 2),
(27, 1, 160.00, 10, 5),
(28, 1, 120.00, 11, 1),
(29, 1, 110.00, 11, 9),
(30, 1, 60.00, 11, 11),
(31, 1, 180.00, 12, 2),
(32, 1, 95.00, 12, 3),
(33, 1, 120.00, 13, 1),
(34, 1, 110.00, 13, 9),
(35, 1, 85.00, 13, 10),
(36, 1, 180.00, 14, 2),
(37, 1, 220.00, 14, 4);

-- pagamento (15)
INSERT INTO pagamento (id_pagamento, data_pagamento, valor, metodo, status, id_consulta) VALUES
(1, '2026-07-06', 260.00, 'PIX', 'APROVADO', 1),
(2, '2026-07-08', 420.00, 'CARTAO', 'APROVADO', 2),
(3, '2026-07-15', 260.00, 'DINHEIRO', 'APROVADO', 3),
(4, '2026-07-22', 710.00, 'CARTAO', 'RECUSADO', 4),
(5, '2026-07-22', 710.00, 'PIX', 'APROVADO', 4),
(6, '2026-08-03', 280.00, 'PIX', 'APROVADO', 5),
(7, '2026-08-12', 500.00, 'CARTAO', 'APROVADO', 6),
(8, '2026-08-19', 290.00, 'DINHEIRO', 'APROVADO', 7),
(9, '2026-08-26', 555.00, 'CARTAO', 'RECUSADO', 8),
(10, '2026-08-27', 555.00, 'PIX', 'APROVADO', 8),
(11, '2026-09-02', 375.00, 'PIX', 'APROVADO', 9),
(12, '2026-09-09', 340.00, 'CARTAO', 'APROVADO', 10),
(13, '2026-09-16', 290.00, 'PIX', 'APROVADO', 11),
(14, '2026-09-23', 275.00, 'DINHEIRO', 'APROVADO', 12),
(15, '2026-10-01', 315.00, 'CARTAO', 'PENDENTE', 13);

-- vacina (6)
INSERT INTO vacina (id_vacina, nome, fabricante, descricao) VALUES
(1, 'V10 (polivalente canina)', 'LabVet Brasil', 'Protege contra cinomose, parvovirose, hepatite infecciosa, leptospirose e outras doenças'),
(2, 'V4 (polivalente felina)', 'BioPet Vacinas', 'Protege contra panleucopenia, rinotraqueíte, calicivirose e clamidiose'),
(3, 'Antirrábica', 'ImunoVet', 'Imunização contra a raiva, exigida por lei'),
(4, 'Gripe canina', 'LabVet Brasil', 'Proteção contra a traqueobronquite infecciosa (tosse dos canis)'),
(5, 'Giárdia', 'BioPet Vacinas', 'Prevenção da giardíase em cães'),
(6, 'FeLV', 'ImunoVet', 'Prevenção da leucemia felina');

-- aplicacao_vacina (24)
INSERT INTO aplicacao_vacina (id_aplicacao, data_aplicacao, lote, id_animal, id_vacina, id_veterinario) VALUES
(1, '2026-01-20', 'V10-25K118', 13, 1, 6),
(2, '2026-02-10', 'V10-25K118', 1, 1, 1),
(3, '2026-02-10', 'AR-25J078', 1, 3, 1),
(4, '2026-02-25', 'V10-25K118', 10, 1, 2),
(5, '2026-02-25', 'GC-26A009', 10, 4, 2),
(6, '2026-03-05', 'V10-25K118', 7, 1, 1),
(7, '2026-03-18', 'V4-25L230', 3, 2, 1),
(8, '2026-03-18', 'AR-25J078', 3, 3, 1),
(9, '2026-04-09', 'V4-25L230', 8, 2, 3),
(10, '2026-05-05', 'AR-25J078', 12, 3, 3),
(11, '2026-05-05', 'GI-26B004', 12, 5, 3),
(12, '2026-05-12', 'V4-25L230', 5, 2, 2),
(13, '2026-06-02', 'GC-26A009', 13, 4, 6),
(14, '2026-06-18', 'V4-25L230', 18, 2, 3),
(15, '2026-06-25', 'V4-25L230', 15, 2, 1),
(16, '2026-08-19', 'V10-26C047', 2, 1, 1),
(17, '2026-09-02', 'V4-26D015', 11, 2, 1),
(18, '2026-09-02', 'AR-26E101', 11, 3, 1),
(19, '2026-09-16', 'V10-26C047', 14, 1, 1),
(20, '2026-10-01', 'V10-26C047', 19, 1, 1),
(21, '2026-10-01', 'AR-26E101', 19, 3, 1),
(22, '2026-10-07', 'V10-26C047', 14, 1, 1),
(23, '2026-10-28', 'V10-26C047', 14, 1, 1),
(24, '2026-10-28', 'AR-26E101', 14, 3, 1);


-- =============================================================================
-- 4. CONSULTAS 01 A 30
-- =============================================================================

-- Questão 01 — Animais e tutores
SELECT
    a.nome AS animal,
    a.especie,
    a.raca,
    t.nome AS tutor,
    t.cidade
FROM animal a
JOIN tutor t ON t.id_tutor = a.id_tutor
ORDER BY a.nome;

-- Questão 02 — Animais por tutor
SELECT
    a.nome AS animal,
    t.nome AS tutor,
    t.email,
    t.telefone
FROM animal a
JOIN tutor t ON t.id_tutor = a.id_tutor
ORDER BY t.nome, a.nome;

-- Questão 03 — Consultas e animais
SELECT
    c.data_hora,
    c.status,
    c.motivo,
    a.nome AS animal
FROM consulta c
JOIN animal a ON a.id_animal = c.id_animal
ORDER BY c.data_hora;

-- Questão 04 — Consultas e veterinários
SELECT
    c.data_hora,
    c.status,
    v.nome AS veterinario,
    v.especialidade
FROM consulta c
JOIN veterinario v ON v.id_veterinario = c.id_veterinario
ORDER BY c.data_hora;

-- Questão 05 — Detalhamento dos atendimentos
SELECT
    c.id_consulta,
    a.nome AS animal,
    v.nome AS veterinario,
    s.nome AS servico,
    ic.quantidade,
    ic.preco_unitario
FROM item_consulta ic
JOIN consulta c ON c.id_consulta = ic.id_consulta
JOIN animal a ON a.id_animal = c.id_animal
JOIN veterinario v ON v.id_veterinario = c.id_veterinario
JOIN servico s ON s.id_servico = ic.id_servico
ORDER BY c.id_consulta, s.nome;

-- Questão 06 — Quantidade de consultas por tutor
SELECT
    t.nome AS tutor,
    COUNT(c.id_consulta) AS qtd_consultas
FROM tutor t
LEFT JOIN animal a ON a.id_tutor = t.id_tutor
LEFT JOIN consulta c ON c.id_animal = a.id_animal
GROUP BY t.id_tutor, t.nome
ORDER BY qtd_consultas DESC, t.nome;

-- Questão 07 — Tutores sem animais
SELECT
    t.id_tutor,
    t.nome,
    t.email,
    t.cidade
FROM tutor t
LEFT JOIN animal a ON a.id_tutor = t.id_tutor
WHERE a.id_animal IS NULL
ORDER BY t.nome;

-- Questão 08 — Quantidade de animais por espécie
SELECT
    a.especie,
    COUNT(*) AS qtd_animais
FROM animal a
GROUP BY a.especie
ORDER BY qtd_animais DESC, a.especie;

-- Questão 09 — Espécie com mais animais
SELECT
    a.especie,
    COUNT(*) AS qtd_animais
FROM animal a
GROUP BY a.especie
HAVING COUNT(*) = (
    SELECT MAX(contagem.qtd)
    FROM (
        SELECT COUNT(*) AS qtd
        FROM animal
        GROUP BY especie
    ) AS contagem
);

-- Questão 10 — Veterinários e consultas
SELECT
    v.nome AS veterinario,
    v.especialidade,
    COUNT(c.id_consulta) AS qtd_consultas
FROM veterinario v
LEFT JOIN consulta c ON c.id_veterinario = v.id_veterinario
GROUP BY v.id_veterinario, v.nome, v.especialidade
ORDER BY qtd_consultas DESC, v.nome;

-- Questão 11 — Veterinários sem consultas
SELECT
    v.id_veterinario,
    v.nome,
    v.especialidade,
    v.crmv
FROM veterinario v
LEFT JOIN consulta c ON c.id_veterinario = v.id_veterinario
WHERE c.id_consulta IS NULL;

-- Questão 12 — Serviço mais caro
SELECT
    s.nome AS servico,
    s.preco,
    cat.nome AS categoria
FROM servico s
JOIN categoria cat ON cat.id_categoria = s.id_categoria
WHERE s.preco = (SELECT MAX(preco) FROM servico);

-- Questão 13 — Serviços nunca utilizados
SELECT
    s.id_servico,
    s.nome AS servico,
    s.preco
FROM servico s
LEFT JOIN item_consulta ic ON ic.id_servico = s.id_servico
WHERE ic.id_item_consulta IS NULL
ORDER BY s.nome;

-- Questão 14 — Serviços por consulta
SELECT
    c.id_consulta,
    c.data_hora,
    a.nome AS animal,
    c.status,
    COUNT(ic.id_item_consulta) AS qtd_itens
FROM consulta c
JOIN animal a ON a.id_animal = c.id_animal
LEFT JOIN item_consulta ic ON ic.id_consulta = c.id_consulta
GROUP BY c.id_consulta, c.data_hora, a.nome, c.status
ORDER BY c.id_consulta;

-- Questão 15 — Serviços mais realizados
SELECT
    s.nome AS servico,
    COUNT(ic.id_item_consulta) AS ocorrencias
FROM servico s
JOIN item_consulta ic ON ic.id_servico = s.id_servico
GROUP BY s.id_servico, s.nome
ORDER BY ocorrencias DESC, s.nome
LIMIT 5;

-- Questão 16 — Consultas e pagamentos
SELECT
    c.id_consulta,
    a.nome AS animal,
    t.nome AS tutor,
    p.valor,
    p.metodo,
    p.status AS status_pagamento
FROM pagamento p
JOIN consulta c ON c.id_consulta = p.id_consulta
JOIN animal a ON a.id_animal = c.id_animal
JOIN tutor t ON t.id_tutor = a.id_tutor
ORDER BY c.id_consulta, p.id_pagamento;

-- Questão 17 — Consultas sem pagamento
SELECT
    c.id_consulta,
    c.data_hora,
    a.nome AS animal,
    c.status
FROM consulta c
JOIN animal a ON a.id_animal = c.id_animal
LEFT JOIN pagamento p ON p.id_consulta = c.id_consulta
WHERE p.id_pagamento IS NULL
ORDER BY c.data_hora;

-- Questão 18 — Histórico de vacinação
SELECT
    a.nome AS animal,
    vac.nome AS vacina,
    av.lote,
    av.data_aplicacao,
    v.nome AS veterinario
FROM aplicacao_vacina av
JOIN animal a ON a.id_animal = av.id_animal
JOIN vacina vac ON vac.id_vacina = av.id_vacina
JOIN veterinario v ON v.id_veterinario = av.id_veterinario
ORDER BY a.nome, av.data_aplicacao, vac.nome;

-- Questão 19 — Animais sem vacinação registrada
SELECT
    a.id_animal,
    a.nome AS animal,
    a.especie,
    a.raca
FROM animal a
LEFT JOIN aplicacao_vacina av ON av.id_animal = a.id_animal
WHERE av.id_aplicacao IS NULL
ORDER BY a.nome;

-- Questão 20 — Média de preço por categoria
SELECT
    cat.nome AS categoria,
    ROUND(AVG(s.preco), 2) AS preco_medio
FROM categoria cat
JOIN servico s ON s.id_categoria = cat.id_categoria
GROUP BY cat.id_categoria, cat.nome
ORDER BY preco_medio DESC;

-- Questão 21 — Quantidade de aplicações por vacina
SELECT
    vac.nome AS vacina,
    COUNT(av.id_aplicacao) AS qtd_aplicacoes
FROM vacina vac
LEFT JOIN aplicacao_vacina av ON av.id_vacina = vac.id_vacina
GROUP BY vac.id_vacina, vac.nome
ORDER BY qtd_aplicacoes DESC, vac.nome;

-- Questão 22 — Quantidade de consultas por status
SELECT
    c.status,
    COUNT(*) AS qtd_consultas
FROM consulta c
GROUP BY c.status
ORDER BY qtd_consultas DESC, c.status;

-- Questão 23 — Valor total por consulta
SELECT
    c.id_consulta,
    a.nome AS animal,
    COALESCE(SUM(ic.quantidade * ic.preco_unitario), 0) AS valor_total
FROM consulta c
JOIN animal a ON a.id_animal = c.id_animal
LEFT JOIN item_consulta ic ON ic.id_consulta = c.id_consulta
GROUP BY c.id_consulta, a.nome
ORDER BY valor_total DESC, c.id_consulta;

-- Questão 24 — Valor total dos atendimentos por tutor
SELECT
    t.nome AS tutor,
    COUNT(DISTINCT c.id_consulta) AS qtd_consultas,
    COALESCE(SUM(ic.quantidade * ic.preco_unitario), 0) AS valor_total_servicos
FROM tutor t
JOIN animal a ON a.id_tutor = t.id_tutor
JOIN consulta c ON c.id_animal = a.id_animal
LEFT JOIN item_consulta ic ON ic.id_consulta = c.id_consulta
GROUP BY t.id_tutor, t.nome
ORDER BY valor_total_servicos DESC, t.nome;

-- Questão 25 — Resumo dos animais
SELECT
    a.nome AS animal,
    a.especie,
    t.nome AS tutor,
    COUNT(DISTINCT c.id_consulta) AS qtd_consultas,
    COUNT(DISTINCT av.id_aplicacao) AS qtd_aplicacoes_vacina
FROM animal a
JOIN tutor t ON t.id_tutor = a.id_tutor
LEFT JOIN consulta c ON c.id_animal = a.id_animal
LEFT JOIN aplicacao_vacina av ON av.id_animal = a.id_animal
GROUP BY a.id_animal, a.nome, a.especie, t.nome
ORDER BY a.nome;

-- Questão 26 — Tutores com muitas consultas
SELECT
    t.nome AS tutor,
    COUNT(c.id_consulta) AS qtd_consultas
FROM tutor t
JOIN animal a ON a.id_tutor = t.id_tutor
JOIN consulta c ON c.id_animal = a.id_animal
GROUP BY t.id_tutor, t.nome
HAVING COUNT(c.id_consulta) > 2
ORDER BY qtd_consultas DESC, t.nome;

-- Questão 27 — Categorias com vários serviços
SELECT
    cat.nome AS categoria,
    COUNT(s.id_servico) AS qtd_servicos
FROM categoria cat
JOIN servico s ON s.id_categoria = cat.id_categoria
GROUP BY cat.id_categoria, cat.nome
HAVING COUNT(s.id_servico) > 2
ORDER BY qtd_servicos DESC, cat.nome;

-- Questão 28 — Animais com vacinação recorrente
SELECT
    a.nome AS animal,
    COUNT(av.id_aplicacao) AS qtd_aplicacoes
FROM animal a
JOIN aplicacao_vacina av ON av.id_animal = a.id_animal
GROUP BY a.id_animal, a.nome
HAVING COUNT(av.id_aplicacao) >= 2
ORDER BY qtd_aplicacoes DESC, a.nome;

-- Questão 29 — Consultas com valor alto
SELECT
    c.id_consulta,
    c.data_hora,
    a.nome AS animal,
    SUM(ic.quantidade * ic.preco_unitario) AS valor_total
FROM consulta c
JOIN animal a ON a.id_animal = c.id_animal
JOIN item_consulta ic ON ic.id_consulta = c.id_consulta
GROUP BY c.id_consulta, c.data_hora, a.nome
HAVING SUM(ic.quantidade * ic.preco_unitario) > 300
ORDER BY valor_total DESC, c.id_consulta;

-- Questão 30 — Relatório geral da clínica
SELECT
    t.nome AS tutor,
    t.cidade,
    COUNT(DISTINCT a.id_animal) AS qtd_animais,
    COUNT(DISTINCT c.id_consulta) AS consultas_realizadas,
    COALESCE(SUM(ic.quantidade * ic.preco_unitario), 0) AS valor_total_servicos
FROM tutor t
JOIN animal a ON a.id_tutor = t.id_tutor
LEFT JOIN consulta c ON c.id_animal = a.id_animal AND c.status = 'REALIZADA'
LEFT JOIN item_consulta ic ON ic.id_consulta = c.id_consulta
GROUP BY t.id_tutor, t.nome, t.cidade
HAVING COUNT(DISTINCT c.id_consulta) > 0
ORDER BY valor_total_servicos DESC, t.nome;
