// =====================================================================
// Ponto único de acesso ao banco de dados do Portal Escolar.
//
// src/db/
//   database.js        -> conexão, migrações e funções query/get/run (este arquivo)
//   schema-sqlite.sql  -> tabelas do banco usado pelo servidor (SQLite)
//   schema-mysql.sql   -> as mesmas tabelas para MySQL
//   seed.js            -> dados de demonstração   (npm run seed)
//   reset.js           -> apaga o banco local     (npm run reset)
//
// Todas as rotas devem acessar o banco somente por este módulo.
// =====================================================================
const fs = require('fs');
const path = require('path');
const initSqlJs = require('sql.js');

const ROOT_DIR = path.join(__dirname, '../..');
const DB_FILE = path.resolve(ROOT_DIR, process.env.DB_FILE || 'data/escola.sqlite');
const SCHEMA_FILE = path.join(__dirname, 'schema-sqlite.sql');

let db;

async function getDb() {
  if (db) return db;
  fs.mkdirSync(path.dirname(DB_FILE), { recursive: true });
  const SQL = await initSqlJs({ locateFile: file => path.join(path.dirname(require.resolve('sql.js')), file) });
  db = fs.existsSync(DB_FILE) ? new SQL.Database(fs.readFileSync(DB_FILE)) : new SQL.Database();
  db.run(fs.readFileSync(SCHEMA_FILE, 'utf8'));
  migrar();
  save();
  return db;
}

// Atualiza bancos criados por versões anteriores do sistema.
// Toda nova alteração de estrutura em banco existente deve entrar aqui.
function migrar() {
  const colunasUsuarios = query('PRAGMA table_info(usuarios)');
  if (!colunasUsuarios.some(c => c.name === 'disciplina')) {
    db.run("ALTER TABLE usuarios ADD COLUMN disciplina TEXT DEFAULT ''");
  }
  // E-mails de usuários criados antes da tabela emails_cadastrados.
  db.run(`INSERT OR IGNORE INTO emails_cadastrados(email, usuario_id, nome, tipo, cadastrado_em)
    SELECT lower(email), id, nome, tipo, criado_em FROM usuarios`);
}

function save() {
  if (!db) return;
  fs.writeFileSync(DB_FILE, Buffer.from(db.export()));
}

function query(sql, params = []) {
  const stmt = db.prepare(sql);
  stmt.bind(params);
  const rows = [];
  while (stmt.step()) rows.push(stmt.getAsObject());
  stmt.free();
  return rows;
}

function get(sql, params = []) {
  return query(sql, params)[0] || null;
}

function run(sql, params = []) {
  db.run(sql, params);
  const id = get('SELECT last_insert_rowid() AS id').id;
  save();
  return id;
}

function resetDb() {
  if (db) { db.close(); db = null; }
  if (fs.existsSync(DB_FILE)) fs.unlinkSync(DB_FILE);
}

module.exports = { getDb, query, get, run, save, resetDb, DB_FILE };
