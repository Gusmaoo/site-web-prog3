# Portal Escolar Acadêmico

Versão de apresentação baseada no Portal Escolar original.

## Perfis de acesso

### Aluno — Área Discente
- Login somente com e-mail discente.
- Consulta de notas.
- Consulta de frequência.
- Plano de estudos organizado pelas menores médias.
- Lista de professores cadastrados com horários disponíveis.
- Agendamento de aula extra.
- O aluno **não consegue lançar ou alterar** notas e frequência.

### Professor — Área Docente
- Login somente com e-mail docente.
- Painel com quantidade de alunos, horários e aulas extras.
- Consulta dos alunos.
- Lançamento e atualização de notas.
- Lançamento e atualização de frequência.
- Cadastro de horários disponíveis para aula extra.
- Consulta das aulas extras agendadas pelos alunos.

## Dados de demonstração

Aluno:
`aluno@escola.com`

Professor:
`professor@escola.com`

Professor adicional:
`prof2@escola.com`

Não há senha no fluxo de demonstração: o tipo de acesso selecionado determina se o e-mail deve ser discente ou docente.

## Como iniciar

```bash
npm install
npm start
```

Depois abra:

`http://localhost:3000`

Veja a seção **Banco de dados** abaixo.


## Contas de demonstração

Aluno principal: aluno@escola.com / 123456
Professor: professor@escola.com / 123456
Professor 2: prof2@escola.com / 123456

Alunos adicionais: cada conta usa a senha indicada abaixo.
- ana.souza@escola.com / Aluno2026@02
- bruno.lima@escola.com / Aluno2026@03
- carlos.santos@escola.com / Aluno2026@04
- daniela.alves@escola.com / Aluno2026@05
- eduardo.costa@escola.com / Aluno2026@06
- fernanda.silva@escola.com / Aluno2026@07
- gabriel.oliveira@escola.com / Aluno2026@08
- helena.martins@escola.com / Aluno2026@09
- igor.rodrigues@escola.com / Aluno2026@10
- juliana.pereira@escola.com / Aluno2026@11

## Banco de dados

Tudo que é de banco fica em `src/db/`:

| Arquivo | Função |
|---|---|
| `database.js` | Único ponto de acesso ao banco: conexão, migrações e funções `query`/`get`/`run` |
| `schema-sqlite.sql` | Tabelas do banco usado pelo servidor (SQLite), aplicado a cada inicialização |
| `schema-mysql.sql` | As mesmas tabelas para MySQL 8 (`mysql -u root -p < src/db/schema-mysql.sql`) |
| `seed.js` | Dados de demonstração (rodado automaticamente no `npm start`) |
| `reset.js` | Apaga o banco local |

O arquivo do banco fica em `data/escola.sqlite` (pode ser alterado com `DB_FILE` no `.env`).

Comandos:

- `npm run seed` — confere/insere os dados de demonstração
- `npm run reset` — apaga o banco (recriado no próximo `npm start`)

Tabelas: `usuarios`, `notas`, `faltas`, `disponibilidades`, `agendamentos`, `recuperacao_senha` e `emails_cadastrados`.
Ao mudar uma tabela, altere os dois schemas; se a mudança precisar valer para bancos já existentes, adicione-a em `migrar()` no `database.js`.

### E-mails cadastrados

Todo e-mail cadastrado no sistema (aluno, professor ou dados de demonstração) é salvo automaticamente
na tabela `emails_cadastrados`, por meio de triggers na tabela `usuarios`.
E-mails de usuários que já existiam são copiados para a tabela ao iniciar o servidor.

Consulta (somente professor logado):

- `GET /api/emails` — todos os e-mails
- `GET /api/emails?tipo=aluno` ou `?tipo=professor` — filtrado por tipo
