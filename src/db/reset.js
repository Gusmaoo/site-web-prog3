require('dotenv').config();
const { resetDb, DB_FILE } = require('./database');
resetDb();
console.log(`Banco apagado (${DB_FILE}). Execute npm start para recriar com os dados de demonstração.`);
