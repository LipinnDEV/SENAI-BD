# Desafios SQL

Repositório com dois desafios práticos de banco de dados desenvolvidos durante os estudos de Desenvolvimento de Sistemas.

## Projetos

### Clínica Veterinária

Modelagem e implementação de um banco de dados para gerenciamento de uma clínica veterinária, incluindo tutores, animais, veterinários, serviços, consultas, pagamentos e vacinação. O script traz 30 consultas SQL.

📁 [clinica_veterinaria.sql](./clinica_veterinaria.sql)

### Biblioteca

Banco de dados para gerenciamento de uma biblioteca, contemplando livros, autores, editoras, exemplares, leitores, funcionários, empréstimos e reservas. Inclui um gatilho que impede o mesmo exemplar em dois empréstimos ativos ao mesmo tempo e 30 consultas SQL.

📁 [desafio_biblioteca.sql](./desafio_biblioteca.sql)

## Tecnologias

- MySQL
- SQL
- DDL e DML
- Relacionamentos e chaves estrangeiras
- Constraints e integridade dos dados
- Consultas SQL
- Triggers

## Como executar

Requisito: MySQL 8.0.16 ou superior.

1. Instale e abra o MySQL Workbench (ou outro cliente MySQL).
2. Abra o arquivo `.sql` do desafio desejado.
3. Execute o script completo.
4. Os scripts criam seus próprios bancos de dados.

Também é possível executar pelo terminal:

```bash
mysql -u root -p < clinica_veterinaria.sql
```

> **Atenção:** os scripts utilizam `DROP DATABASE IF EXISTS` e recriam os bancos. Isso apaga os bancos anteriores com esses nomes e seus dados.

## Autor

**Felipe da Silva Mousinho**  
Estudante de Desenvolvimento de Sistemas

- GitHub: [LipinnDEV](https://github.com/LipinnDEV)

---

Projeto desenvolvido para fins acadêmicos e prática de SQL.
