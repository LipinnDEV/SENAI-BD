DROP DATABASE IF EXISTS desafio_biblioteca;
CREATE DATABASE desafio_biblioteca
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE desafio_biblioteca;

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

-- Tabela: editora
CREATE TABLE editora (
    id_editora INT NOT NULL AUTO_INCREMENT,
    nome VARCHAR(100) NOT NULL,
    cidade VARCHAR(60) NOT NULL,
    email VARCHAR(120) NOT NULL,
    PRIMARY KEY (id_editora),
    CONSTRAINT uq_editora_nome UNIQUE (nome),
    CONSTRAINT chk_editora_email CHECK (email LIKE '%_@_%')
) ENGINE = InnoDB;

-- Tabela: autor
CREATE TABLE autor (
    id_autor INT NOT NULL AUTO_INCREMENT,
    nome VARCHAR(100) NOT NULL,
    pais_origem VARCHAR(60) NOT NULL,
    data_nascimento DATE,
    PRIMARY KEY (id_autor)
) ENGINE = InnoDB;

-- Tabela: livro
CREATE TABLE livro (
    id_livro INT NOT NULL AUTO_INCREMENT,
    titulo VARCHAR(150) NOT NULL,
    isbn CHAR(13) NOT NULL,
    ano_publicacao SMALLINT NOT NULL,
    id_categoria INT NOT NULL,
    id_editora INT NOT NULL,
    PRIMARY KEY (id_livro),
    CONSTRAINT uq_livro_isbn UNIQUE (isbn),
    CONSTRAINT chk_livro_isbn CHECK (isbn REGEXP '^[0-9]{13}$'),
    CONSTRAINT chk_livro_ano CHECK (ano_publicacao BETWEEN 1400 AND 2100),
    CONSTRAINT fk_livro_categoria FOREIGN KEY (id_categoria)
        REFERENCES categoria (id_categoria)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_livro_editora FOREIGN KEY (id_editora)
        REFERENCES editora (id_editora)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB;

-- Tabela: livro_autor
CREATE TABLE livro_autor (
    id_livro INT NOT NULL,
    id_autor INT NOT NULL,
    PRIMARY KEY (id_livro, id_autor),
    CONSTRAINT fk_livro_autor_livro FOREIGN KEY (id_livro)
        REFERENCES livro (id_livro)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_livro_autor_autor FOREIGN KEY (id_autor)
        REFERENCES autor (id_autor)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE = InnoDB;

-- Tabela: exemplar
CREATE TABLE exemplar (
    id_exemplar INT NOT NULL AUTO_INCREMENT,
    codigo_patrimonio VARCHAR(20) NOT NULL,
    status ENUM('DISPONIVEL','EMPRESTADO','RESERVADO','INATIVO') NOT NULL DEFAULT 'DISPONIVEL',
    id_livro INT NOT NULL,
    PRIMARY KEY (id_exemplar),
    CONSTRAINT uq_exemplar_patrimonio UNIQUE (codigo_patrimonio),
    CONSTRAINT fk_exemplar_livro FOREIGN KEY (id_livro)
        REFERENCES livro (id_livro)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB;

-- Tabela: leitor
CREATE TABLE leitor (
    id_leitor INT NOT NULL AUTO_INCREMENT,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(120) NOT NULL,
    telefone VARCHAR(20) NOT NULL,
    cidade VARCHAR(60) NOT NULL,
    data_cadastro DATE NOT NULL,
    PRIMARY KEY (id_leitor),
    CONSTRAINT uq_leitor_email UNIQUE (email),
    CONSTRAINT chk_leitor_email CHECK (email LIKE '%_@_%')
) ENGINE = InnoDB;

-- Tabela: funcionario
CREATE TABLE funcionario (
    id_funcionario INT NOT NULL AUTO_INCREMENT,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(120) NOT NULL,
    matricula VARCHAR(20) NOT NULL,
    PRIMARY KEY (id_funcionario),
    CONSTRAINT uq_funcionario_email UNIQUE (email),
    CONSTRAINT uq_funcionario_matricula UNIQUE (matricula)
) ENGINE = InnoDB;

-- Tabela: emprestimo
CREATE TABLE emprestimo (
    id_emprestimo INT NOT NULL AUTO_INCREMENT,
    data_emprestimo DATE NOT NULL,
    data_prevista_devolucao DATE NOT NULL,
    data_devolucao DATE,
    status ENUM('ATIVO','DEVOLVIDO','ATRASADO') NOT NULL DEFAULT 'ATIVO',
    id_leitor INT NOT NULL,
    id_funcionario INT NOT NULL,
    PRIMARY KEY (id_emprestimo),
    CONSTRAINT chk_emprestimo_prazo CHECK (data_prevista_devolucao >= data_emprestimo),
    CONSTRAINT chk_emprestimo_devolucao CHECK (data_devolucao IS NULL OR data_devolucao >= data_emprestimo),
    CONSTRAINT chk_emprestimo_status_devolucao CHECK (
        (status = 'DEVOLVIDO' AND data_devolucao IS NOT NULL)
        OR (status <> 'DEVOLVIDO' AND data_devolucao IS NULL)
    ),
    CONSTRAINT fk_emprestimo_leitor FOREIGN KEY (id_leitor)
        REFERENCES leitor (id_leitor)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_emprestimo_funcionario FOREIGN KEY (id_funcionario)
        REFERENCES funcionario (id_funcionario)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB;

-- Tabela: item_emprestimo
CREATE TABLE item_emprestimo (
    id_item_emprestimo INT NOT NULL AUTO_INCREMENT,
    id_emprestimo INT NOT NULL,
    id_exemplar INT NOT NULL,
    PRIMARY KEY (id_item_emprestimo),
    CONSTRAINT uq_item_emprestimo_exemplar UNIQUE (id_emprestimo, id_exemplar),
    CONSTRAINT fk_item_emprestimo_emprestimo FOREIGN KEY (id_emprestimo)
        REFERENCES emprestimo (id_emprestimo)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_item_emprestimo_exemplar FOREIGN KEY (id_exemplar)
        REFERENCES exemplar (id_exemplar)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB;

-- Tabela: reserva
CREATE TABLE reserva (
    id_reserva INT NOT NULL AUTO_INCREMENT,
    data_reserva DATE NOT NULL,
    status ENUM('PENDENTE','ATENDIDA','CANCELADA') NOT NULL DEFAULT 'PENDENTE',
    id_leitor INT NOT NULL,
    id_livro INT NOT NULL,
    PRIMARY KEY (id_reserva),
    CONSTRAINT fk_reserva_leitor FOREIGN KEY (id_leitor)
        REFERENCES leitor (id_leitor)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_reserva_livro FOREIGN KEY (id_livro)
        REFERENCES livro (id_livro)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB;

-- Gatilho: impede o mesmo exemplar em dois empréstimos ativos
DELIMITER $$

CREATE TRIGGER trg_item_emprestimo_exemplar_livre
BEFORE INSERT ON item_emprestimo
FOR EACH ROW
BEGIN
    DECLARE v_status_novo VARCHAR(10);
    DECLARE v_em_aberto INT DEFAULT 0;

    SELECT e.status INTO v_status_novo
    FROM emprestimo e
    WHERE e.id_emprestimo = NEW.id_emprestimo;

    IF v_status_novo IN ('ATIVO', 'ATRASADO') THEN
        SELECT COUNT(*) INTO v_em_aberto
        FROM item_emprestimo ie
        JOIN emprestimo e ON e.id_emprestimo = ie.id_emprestimo
        WHERE ie.id_exemplar = NEW.id_exemplar
          AND e.status IN ('ATIVO', 'ATRASADO');

        IF v_em_aberto > 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Exemplar ja esta em outro emprestimo ativo';
        END IF;
    END IF;
END$$

DELIMITER ;


-- =============================================================================
-- 3. INSERÇÃO DOS DADOS
-- =============================================================================

-- categoria (5)
INSERT INTO categoria (id_categoria, nome, descricao) VALUES
(1, 'Literatura', 'Romances, contos e poesia'),
(2, 'Tecnologia', 'Programação, redes e computação'),
(3, 'História', 'História do Brasil e do mundo'),
(4, 'Ciências', 'Ciências naturais e divulgação científica'),
(5, 'Educação', 'Pedagogia e práticas de ensino');

-- editora (6)
INSERT INTO editora (id_editora, nome, cidade, email) VALUES
(1, 'Editora Aurora', 'São Paulo', 'contato@aurora.example.com'),
(2, 'Horizonte Livros', 'Rio de Janeiro', 'contato@horizonte.example.com'),
(3, 'Casa do Vale', 'Florianópolis', 'contato@casadovale.example.com'),
(4, 'Pioneira Técnica', 'Porto Alegre', 'contato@pioneira.example.com'),
(5, 'Nova Era Editorial', 'Curitiba', 'contato@novaera.example.com'),
(6, 'Folha Verde Edições', 'Belo Horizonte', 'contato@folhaverde.example.com');

-- autor (12)
INSERT INTO autor (id_autor, nome, pais_origem, data_nascimento) VALUES
(1, 'Rodrigo Menezes', 'Brasil', '1971-04-12'),
(2, 'Helena Barbosa', 'Brasil', '1965-09-23'),
(3, 'Miguel Alvarenga', 'Portugal', '1958-02-17'),
(4, 'Sofía Ledesma', 'Argentina', '1969-11-30'),
(5, 'Daniel Whitmore', 'Reino Unido', '1962-07-08'),
(6, 'Hannah Keller', 'Estados Unidos', '1975-01-19'),
(7, 'Camila Torres', 'Brasil', '1980-06-05'),
(8, 'Takeshi Mori', 'Japão', '1955-12-02'),
(9, 'Beatriz Nogueira', 'Brasil', '1949-03-14'),
(10, 'Lucas Pereira', 'Brasil', '1987-08-26'),
(11, 'Isabel Fontes', 'Portugal', '1973-10-09'),
(12, 'Gustavo Rangel', 'Brasil', '1990-05-21');

-- livro (15)
INSERT INTO livro (id_livro, titulo, isbn, ano_publicacao, id_categoria, id_editora) VALUES
(1, 'O Vento nas Cartas', '9788530124571', 2008, 1, 1),
(2, 'Cidade de Névoa', '9788530218638', 2015, 1, 1),
(3, 'As Marés de Julho', '9788529981048', 1998, 1, 2),
(4, 'Memórias de um Faroleiro', '9788528743166', 1987, 1, 2),
(5, 'A Casa dos Ipês', '9788531509278', 2019, 1, 3),
(6, 'Programação Java na Prática', '9788532655813', 2021, 2, 4),
(7, 'Banco de Dados Relacionais com MySQL', '9788532740922', 2019, 2, 4),
(8, 'Algoritmos e Estruturas de Dados', '9788531896309', 2017, 2, 5),
(9, 'Redes de Computadores Essencial', '9788533027459', 2020, 2, 5),
(10, 'Brasil Colonial: Cotidiano e Poder', '9788529518732', 2005, 3, 2),
(11, 'Europa entre Guerras', '9788530981266', 2012, 3, 5),
(12, 'O Universo ao Alcance', '9788532174499', 2016, 4, 3),
(13, 'Fundamentos de Biologia Moderna', '9788532438058', 2018, 4, 5),
(14, 'Didática para o Século XXI', '9788530719524', 2014, 5, 2),
(15, 'Educação e Tecnologia nas Escolas', '9788533506183', 2022, 5, 1);

-- livro_autor (21)
INSERT INTO livro_autor (id_livro, id_autor) VALUES
(1, 1),
(1, 2),
(2, 1),
(3, 3),
(4, 3),
(5, 4),
(6, 7),
(6, 10),
(7, 10),
(8, 5),
(8, 7),
(9, 5),
(9, 6),
(10, 9),
(10, 11),
(11, 11),
(12, 8),
(13, 8),
(14, 9),
(15, 7),
(15, 10);

-- exemplar (25)
INSERT INTO exemplar (id_exemplar, codigo_patrimonio, status, id_livro) VALUES
(1, 'BIB-0001', 'DISPONIVEL', 1),
(2, 'BIB-0002', 'EMPRESTADO', 1),
(3, 'BIB-0003', 'DISPONIVEL', 2),
(4, 'BIB-0004', 'EMPRESTADO', 2),
(5, 'BIB-0005', 'DISPONIVEL', 3),
(6, 'BIB-0006', 'INATIVO', 3),
(7, 'BIB-0007', 'EMPRESTADO', 4),
(8, 'BIB-0008', 'DISPONIVEL', 5),
(9, 'BIB-0009', 'EMPRESTADO', 5),
(10, 'BIB-0010', 'RESERVADO', 6),
(11, 'BIB-0011', 'EMPRESTADO', 6),
(12, 'BIB-0012', 'EMPRESTADO', 6),
(13, 'BIB-0013', 'EMPRESTADO', 7),
(14, 'BIB-0014', 'EMPRESTADO', 7),
(15, 'BIB-0015', 'DISPONIVEL', 8),
(16, 'BIB-0016', 'RESERVADO', 8),
(17, 'BIB-0017', 'DISPONIVEL', 9),
(18, 'BIB-0018', 'EMPRESTADO', 9),
(19, 'BIB-0019', 'EMPRESTADO', 10),
(20, 'BIB-0020', 'DISPONIVEL', 11),
(21, 'BIB-0021', 'RESERVADO', 12),
(22, 'BIB-0022', 'EMPRESTADO', 12),
(23, 'BIB-0023', 'DISPONIVEL', 13),
(24, 'BIB-0024', 'INATIVO', 14),
(25, 'BIB-0025', 'EMPRESTADO', 15);

-- leitor (15)
INSERT INTO leitor (id_leitor, nome, email, telefone, cidade, data_cadastro) VALUES
(1, 'Aline Souza', 'aline.souza@example.com', '(47) 99888-0001', 'Blumenau', '2023-02-14'),
(2, 'Bruno Carvalho', 'bruno.carvalho@example.com', '(47) 99888-0002', 'Gaspar', '2023-03-20'),
(3, 'Carla Mendes', 'carla.mendes@example.com', '(47) 99888-0003', 'Indaial', '2023-05-08'),
(4, 'Diego Ramos', 'diego.ramos@example.com', '(47) 99888-0004', 'Blumenau', '2023-08-15'),
(5, 'Eduarda Lima', 'eduarda.lima@example.com', '(47) 99888-0005', 'Pomerode', '2024-01-22'),
(6, 'Fábio Teixeira', 'fabio.teixeira@example.com', '(47) 99888-0006', 'Timbó', '2024-02-10'),
(7, 'Gabriela Rocha', 'gabriela.rocha@example.com', '(47) 99888-0007', 'Blumenau', '2024-04-03'),
(8, 'Heitor Barros', 'heitor.barros@example.com', '(47) 99888-0008', 'Brusque', '2024-06-18'),
(9, 'Isadora Pires', 'isadora.pires@example.com', '(47) 99888-0009', 'Blumenau', '2024-09-09'),
(10, 'João Victor Alves', 'joao.alves@example.com', '(47) 99888-0010', 'Joinville', '2025-01-13'),
(11, 'Karina Duarte', 'karina.duarte@example.com', '(47) 99888-0011', 'Gaspar', '2025-03-27'),
(12, 'Leandro Gomes', 'leandro.gomes@example.com', '(47) 99888-0012', 'Blumenau', '2025-06-30'),
(13, 'Mariana Freitas', 'mariana.freitas@example.com', '(47) 99888-0013', 'Indaial', '2025-09-15'),
(14, 'Nicolas Batista', 'nicolas.batista@example.com', '(47) 99888-0014', 'Blumenau', '2026-03-11'),
(15, 'Olívia Cardoso', 'olivia.cardoso@example.com', '(47) 99888-0015', 'Pomerode', '2026-08-02');

-- funcionario (5)
INSERT INTO funcionario (id_funcionario, nome, email, matricula) VALUES
(1, 'Ricardo Almeida', 'ricardo.almeida@biblioteca.example.com', 'F-0001'),
(2, 'Patrícia Lopes', 'patricia.lopes@biblioteca.example.com', 'F-0002'),
(3, 'Sérgio Nunes', 'sergio.nunes@biblioteca.example.com', 'F-0003'),
(4, 'Tatiane Costa', 'tatiane.costa@biblioteca.example.com', 'F-0004'),
(5, 'Vinícius Prado', 'vinicius.prado@biblioteca.example.com', 'F-0005');

-- emprestimo (20)
INSERT INTO emprestimo (id_emprestimo, data_emprestimo, data_prevista_devolucao, data_devolucao, status, id_leitor, id_funcionario) VALUES
(1, '2026-06-02', '2026-06-16', '2026-06-15', 'DEVOLVIDO', 1, 1),
(2, '2026-06-05', '2026-06-19', '2026-06-19', 'DEVOLVIDO', 2, 2),
(3, '2026-06-10', '2026-06-24', '2026-06-30', 'DEVOLVIDO', 3, 1),
(4, '2026-06-15', '2026-06-29', '2026-06-28', 'DEVOLVIDO', 4, 3),
(5, '2026-07-01', '2026-07-15', '2026-07-14', 'DEVOLVIDO', 1, 2),
(6, '2026-07-08', '2026-07-22', '2026-07-22', 'DEVOLVIDO', 5, 4),
(7, '2026-07-20', '2026-08-03', '2026-08-01', 'DEVOLVIDO', 6, 3),
(8, '2026-08-04', '2026-08-18', '2026-08-17', 'DEVOLVIDO', 1, 1),
(9, '2026-08-12', '2026-08-26', '2026-08-25', 'DEVOLVIDO', 7, 2),
(10, '2026-08-25', '2026-09-08', '2026-09-10', 'DEVOLVIDO', 8, 4),
(11, '2026-09-03', '2026-09-17', '2026-09-16', 'DEVOLVIDO', 9, 3),
(12, '2026-09-15', '2026-09-29', '2026-09-29', 'DEVOLVIDO', 3, 1),
(13, '2026-09-20', '2026-10-04', NULL, 'ATRASADO', 10, 2),
(14, '2026-09-28', '2026-10-12', NULL, 'ATRASADO', 11, 4),
(15, '2026-10-05', '2026-10-19', NULL, 'ATRASADO', 10, 1),
(16, '2026-10-12', '2026-10-26', NULL, 'ATRASADO', 12, 3),
(17, '2026-10-26', '2026-11-09', NULL, 'ATIVO', 13, 2),
(18, '2026-10-28', '2026-11-11', NULL, 'ATIVO', 1, 4),
(19, '2026-10-30', '2026-11-13', NULL, 'ATIVO', 12, 1),
(20, '2026-11-02', '2026-11-16', NULL, 'ATIVO', 3, 2);

-- item_emprestimo (29)
INSERT INTO item_emprestimo (id_item_emprestimo, id_emprestimo, id_exemplar) VALUES
(1, 1, 10),
(2, 2, 1),
(3, 2, 5),
(4, 3, 13),
(5, 4, 15),
(6, 5, 11),
(7, 6, 3),
(8, 6, 8),
(9, 7, 10),
(10, 8, 17),
(11, 8, 21),
(12, 9, 1),
(13, 10, 6),
(14, 10, 24),
(15, 11, 12),
(16, 11, 15),
(17, 12, 16),
(18, 13, 7),
(19, 13, 13),
(20, 14, 19),
(21, 15, 18),
(22, 16, 4),
(23, 16, 2),
(24, 17, 11),
(25, 18, 22),
(26, 19, 25),
(27, 19, 12),
(28, 20, 9),
(29, 20, 14);

-- reserva (14)
INSERT INTO reserva (id_reserva, data_reserva, status, id_leitor, id_livro) VALUES
(1, '2026-07-10', 'ATENDIDA', 6, 6),
(2, '2026-07-12', 'ATENDIDA', 7, 1),
(3, '2026-08-02', 'CANCELADA', 2, 7),
(4, '2026-08-20', 'ATENDIDA', 3, 8),
(5, '2026-08-28', 'ATENDIDA', 9, 6),
(6, '2026-09-05', 'CANCELADA', 4, 6),
(7, '2026-09-18', 'ATENDIDA', 13, 6),
(8, '2026-10-08', 'PENDENTE', 4, 6),
(9, '2026-10-15', 'PENDENTE', 1, 7),
(10, '2026-10-22', 'PENDENTE', 8, 12),
(11, '2026-10-25', 'PENDENTE', 3, 8),
(12, '2026-10-29', 'PENDENTE', 11, 10),
(13, '2026-10-30', 'CANCELADA', 10, 14),
(14, '2026-11-03', 'PENDENTE', 2, 15);


-- =============================================================================
-- 4. CONSULTAS 01 A 30
-- =============================================================================

-- Questão 01 — Livros e categorias
SELECT
    l.titulo,
    l.ano_publicacao,
    cat.nome AS categoria
FROM livro l
JOIN categoria cat ON cat.id_categoria = l.id_categoria
ORDER BY l.titulo;

-- Questão 02 — Livros e editoras
SELECT
    l.titulo,
    l.isbn,
    ed.nome AS editora,
    ed.cidade AS cidade_editora
FROM livro l
JOIN editora ed ON ed.id_editora = l.id_editora
ORDER BY l.titulo;

-- Questão 03 — Livros e autores
SELECT
    l.titulo,
    au.nome AS autor
FROM livro l
JOIN livro_autor la ON la.id_livro = l.id_livro
JOIN autor au ON au.id_autor = la.id_autor
ORDER BY l.titulo, au.nome;

-- Questão 04 — Acervo completo
SELECT
    l.titulo,
    cat.nome AS categoria,
    ed.nome AS editora,
    au.nome AS autor
FROM livro l
JOIN categoria cat ON cat.id_categoria = l.id_categoria
JOIN editora ed ON ed.id_editora = l.id_editora
JOIN livro_autor la ON la.id_livro = l.id_livro
JOIN autor au ON au.id_autor = la.id_autor
ORDER BY l.titulo, au.nome;

-- Questão 05 — Exemplares por livro
SELECT
    l.titulo,
    ex.codigo_patrimonio,
    ex.status
FROM exemplar ex
JOIN livro l ON l.id_livro = ex.id_livro
ORDER BY l.titulo, ex.codigo_patrimonio;

-- Questão 06 — Quantidade de empréstimos por leitor
SELECT
    le.nome AS leitor,
    COUNT(em.id_emprestimo) AS qtd_emprestimos
FROM leitor le
LEFT JOIN emprestimo em ON em.id_leitor = le.id_leitor
GROUP BY le.id_leitor, le.nome
ORDER BY qtd_emprestimos DESC, le.nome;

-- Questão 07 — Leitores sem empréstimos
SELECT
    le.id_leitor,
    le.nome,
    le.email,
    le.cidade
FROM leitor le
LEFT JOIN emprestimo em ON em.id_leitor = le.id_leitor
WHERE em.id_emprestimo IS NULL
ORDER BY le.nome;

-- Questão 08 — Quantidade de livros por categoria
SELECT
    cat.nome AS categoria,
    COUNT(l.id_livro) AS qtd_titulos
FROM categoria cat
LEFT JOIN livro l ON l.id_categoria = cat.id_categoria
GROUP BY cat.id_categoria, cat.nome
ORDER BY qtd_titulos DESC, cat.nome;

-- Questão 09 — Categoria com mais livros
SELECT
    cat.nome AS categoria,
    COUNT(l.id_livro) AS qtd_titulos
FROM categoria cat
JOIN livro l ON l.id_categoria = cat.id_categoria
GROUP BY cat.id_categoria, cat.nome
HAVING COUNT(l.id_livro) = (
    SELECT MAX(contagem.qtd)
    FROM (
        SELECT COUNT(*) AS qtd
        FROM livro
        GROUP BY id_categoria
    ) AS contagem
);

-- Questão 10 — Editoras e títulos publicados
SELECT
    ed.nome AS editora,
    ed.cidade,
    COUNT(l.id_livro) AS qtd_livros
FROM editora ed
LEFT JOIN livro l ON l.id_editora = ed.id_editora
GROUP BY ed.id_editora, ed.nome, ed.cidade
ORDER BY qtd_livros DESC, ed.nome;

-- Questão 11 — Editoras sem livros
SELECT
    ed.id_editora,
    ed.nome,
    ed.cidade,
    ed.email
FROM editora ed
LEFT JOIN livro l ON l.id_editora = ed.id_editora
WHERE l.id_livro IS NULL;

-- Questão 12 — Livro mais antigo
SELECT
    l.titulo,
    l.ano_publicacao,
    cat.nome AS categoria
FROM livro l
JOIN categoria cat ON cat.id_categoria = l.id_categoria
WHERE l.ano_publicacao = (SELECT MIN(ano_publicacao) FROM livro);

-- Questão 13 — Livros nunca emprestados
SELECT
    l.id_livro,
    l.titulo,
    l.ano_publicacao
FROM livro l
LEFT JOIN (
    SELECT DISTINCT ex.id_livro
    FROM exemplar ex
    JOIN item_emprestimo ie ON ie.id_exemplar = ex.id_exemplar
) AS emprestados ON emprestados.id_livro = l.id_livro
WHERE emprestados.id_livro IS NULL
ORDER BY l.titulo;

-- Questão 14 — Itens por empréstimo
SELECT
    em.id_emprestimo,
    le.nome AS leitor,
    COUNT(ie.id_item_emprestimo) AS qtd_exemplares
FROM emprestimo em
JOIN leitor le ON le.id_leitor = em.id_leitor
JOIN item_emprestimo ie ON ie.id_emprestimo = em.id_emprestimo
GROUP BY em.id_emprestimo, le.nome
ORDER BY em.id_emprestimo;

-- Questão 15 — Livros mais emprestados
SELECT
    l.titulo,
    COUNT(ie.id_item_emprestimo) AS vezes_emprestado
FROM livro l
JOIN exemplar ex ON ex.id_livro = l.id_livro
JOIN item_emprestimo ie ON ie.id_exemplar = ex.id_exemplar
GROUP BY l.id_livro, l.titulo
ORDER BY vezes_emprestado DESC, l.titulo;

-- Questão 16 — Empréstimos e funcionários
SELECT
    em.id_emprestimo,
    le.nome AS leitor,
    fu.nome AS funcionario,
    em.data_emprestimo,
    em.status
FROM emprestimo em
JOIN leitor le ON le.id_leitor = em.id_leitor
JOIN funcionario fu ON fu.id_funcionario = em.id_funcionario
ORDER BY em.id_emprestimo;

-- Questão 17 — Empréstimos sem devolução
SELECT
    em.id_emprestimo,
    le.nome AS leitor,
    em.data_emprestimo,
    em.data_prevista_devolucao,
    em.status
FROM emprestimo em
JOIN leitor le ON le.id_leitor = em.id_leitor
WHERE em.status IN ('ATIVO', 'ATRASADO')
ORDER BY em.data_prevista_devolucao, em.id_emprestimo;

-- Questão 18 — Histórico de empréstimos
SELECT
    le.nome AS leitor,
    l.titulo,
    ex.codigo_patrimonio,
    em.data_emprestimo,
    em.data_devolucao
FROM emprestimo em
JOIN leitor le ON le.id_leitor = em.id_leitor
JOIN item_emprestimo ie ON ie.id_emprestimo = em.id_emprestimo
JOIN exemplar ex ON ex.id_exemplar = ie.id_exemplar
JOIN livro l ON l.id_livro = ex.id_livro
ORDER BY le.nome, em.data_emprestimo, l.titulo;

-- Questão 19 — Livros sem exemplar disponível
SELECT
    l.id_livro,
    l.titulo
FROM livro l
LEFT JOIN exemplar ex ON ex.id_livro = l.id_livro AND ex.status = 'DISPONIVEL'
WHERE ex.id_exemplar IS NULL
ORDER BY l.titulo;

-- Questão 20 — Média de empréstimos por categoria
SELECT
    cat.nome AS categoria,
    ROUND(AVG(por_livro.qtd_emprestimos), 2) AS media_emprestimos_por_titulo
FROM categoria cat
JOIN livro l ON l.id_categoria = cat.id_categoria
JOIN (
    SELECT
        ex.id_livro,
        COUNT(ie.id_item_emprestimo) AS qtd_emprestimos
    FROM exemplar ex
    JOIN item_emprestimo ie ON ie.id_exemplar = ex.id_exemplar
    GROUP BY ex.id_livro
) AS por_livro ON por_livro.id_livro = l.id_livro
GROUP BY cat.id_categoria, cat.nome
ORDER BY media_emprestimos_por_titulo DESC, cat.nome;

-- Questão 21 — Quantidade de reservas por livro
SELECT
    l.titulo,
    COUNT(rs.id_reserva) AS qtd_reservas
FROM livro l
LEFT JOIN reserva rs ON rs.id_livro = l.id_livro
GROUP BY l.id_livro, l.titulo
ORDER BY qtd_reservas DESC, l.titulo;

-- Questão 22 — Empréstimos por status
SELECT
    em.status,
    COUNT(*) AS qtd_emprestimos
FROM emprestimo em
GROUP BY em.status
ORDER BY qtd_emprestimos DESC, em.status;

-- Questão 23 — Leitores com devoluções atrasadas
SELECT
    le.nome AS leitor,
    COUNT(em.id_emprestimo) AS qtd_atrasados
FROM leitor le
JOIN emprestimo em ON em.id_leitor = le.id_leitor
WHERE em.status = 'ATRASADO'
GROUP BY le.id_leitor, le.nome
ORDER BY qtd_atrasados DESC, le.nome;

-- Questão 24 — Quantidade de empréstimos por funcionário
SELECT
    fu.nome AS funcionario,
    COUNT(em.id_emprestimo) AS qtd_emprestimos
FROM funcionario fu
LEFT JOIN emprestimo em ON em.id_funcionario = fu.id_funcionario
GROUP BY fu.id_funcionario, fu.nome
ORDER BY qtd_emprestimos DESC, fu.nome;

-- Questão 25 — Resumo por leitor
SELECT
    le.nome AS leitor,
    COUNT(DISTINCT em.id_emprestimo) AS qtd_emprestimos,
    COUNT(DISTINCT rs.id_reserva) AS qtd_reservas
FROM leitor le
LEFT JOIN emprestimo em ON em.id_leitor = le.id_leitor
LEFT JOIN reserva rs ON rs.id_leitor = le.id_leitor
GROUP BY le.id_leitor, le.nome
ORDER BY le.nome;

-- Questão 26 — Leitores com muitos empréstimos
SELECT
    le.nome AS leitor,
    COUNT(em.id_emprestimo) AS qtd_emprestimos
FROM leitor le
JOIN emprestimo em ON em.id_leitor = le.id_leitor
GROUP BY le.id_leitor, le.nome
HAVING COUNT(em.id_emprestimo) > 2
ORDER BY qtd_emprestimos DESC, le.nome;

-- Questão 27 — Categorias com vários títulos
SELECT
    cat.nome AS categoria,
    COUNT(l.id_livro) AS qtd_livros
FROM categoria cat
JOIN livro l ON l.id_categoria = cat.id_categoria
GROUP BY cat.id_categoria, cat.nome
HAVING COUNT(l.id_livro) > 2
ORDER BY qtd_livros DESC, cat.nome;

-- Questão 28 — Livros com alta procura
SELECT
    l.titulo,
    COUNT(ie.id_item_emprestimo) AS qtd_emprestimos
FROM livro l
JOIN exemplar ex ON ex.id_livro = l.id_livro
JOIN item_emprestimo ie ON ie.id_exemplar = ex.id_exemplar
GROUP BY l.id_livro, l.titulo
HAVING COUNT(ie.id_item_emprestimo) >= 3
ORDER BY qtd_emprestimos DESC, l.titulo;

-- Questão 29 — Leitores com empréstimos ativos
SELECT
    le.nome AS leitor,
    COUNT(em.id_emprestimo) AS qtd_em_aberto
FROM leitor le
JOIN emprestimo em ON em.id_leitor = le.id_leitor
WHERE em.status IN ('ATIVO', 'ATRASADO')
GROUP BY le.id_leitor, le.nome
HAVING COUNT(em.id_emprestimo) > 1
ORDER BY qtd_em_aberto DESC, le.nome;

-- Questão 30 — Relatório geral do acervo
SELECT
    cat.nome AS categoria,
    COUNT(DISTINCT l.id_livro) AS qtd_titulos,
    COUNT(DISTINCT ex.id_exemplar) AS qtd_exemplares,
    COUNT(DISTINCT ie.id_emprestimo) AS qtd_emprestimos,
    COUNT(DISTINCT rs.id_reserva) AS qtd_reservas
FROM categoria cat
LEFT JOIN livro l ON l.id_categoria = cat.id_categoria
LEFT JOIN exemplar ex ON ex.id_livro = l.id_livro
LEFT JOIN item_emprestimo ie ON ie.id_exemplar = ex.id_exemplar
LEFT JOIN reserva rs ON rs.id_livro = l.id_livro
GROUP BY cat.id_categoria, cat.nome
ORDER BY qtd_emprestimos DESC, cat.nome;
