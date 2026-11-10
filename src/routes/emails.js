const express = require('express');
const { get, query } = require('../db/database');
const auth = require('./auth');
const router = express.Router();

function professor(req, res) {
  const token = req.headers.authorization?.replace('Bearer ', '');
  const id = token && auth.sessions.get(token);
  const u = id ? get('SELECT id, tipo FROM usuarios WHERE id=?', [id]) : null;
  if (!u) { res.status(401).json({ erro: 'Não autenticado.' }); return null; }
  if (u.tipo !== 'professor') { res.status(403).json({ erro: 'Acesso exclusivo para professores.' }); return null; }
  return u;
}

// GET /api/emails?tipo=aluno|professor  -> lista todos os e-mails cadastrados
router.get('/', (req, res) => {
  if (!professor(req, res)) return;
  const tipo = String(req.query.tipo || '').toLowerCase();
  const rows = ['aluno', 'professor', 'admin'].includes(tipo)
    ? query('SELECT id, email, nome, tipo, usuario_id, cadastrado_em FROM emails_cadastrados WHERE tipo=? ORDER BY cadastrado_em DESC, id DESC', [tipo])
    : query('SELECT id, email, nome, tipo, usuario_id, cadastrado_em FROM emails_cadastrados ORDER BY cadastrado_em DESC, id DESC');
  res.json({ total: rows.length, emails: rows });
});

module.exports = router;
