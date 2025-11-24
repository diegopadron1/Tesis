// config/db.config.js
require('dotenv').config();

module.exports = {
  // Usamos el valor del .env, o el valor 'string' por defecto si falla
  HOST: process.env.DB_HOST || "localhost",
  USER: process.env.DB_USER || "tesis",
  PASSWORD: process.env.DB_PASS || "tesis", 
  DB: process.env.DB_NAME || "historia_clinica",
  dialect: "postgres",
  pool: {
    max: 5,
    min: 0,
    acquire: 30000,
    idle: 10000
  }
};