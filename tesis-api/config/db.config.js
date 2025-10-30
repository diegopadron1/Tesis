// config/db.config.js
require('dotenv').config(); // Carga las variables del archivo .env
const { Sequelize } = require('sequelize');

// Crea una nueva instancia de Sequelize para la conexión
const sequelize = new Sequelize(
  process.env.DB_NAME,      // 'historia_clinica'
  process.env.DB_USER,      // 'tesis'
  process.env.DB_PASS,      // 'tesis'
  {
    host: process.env.DB_HOST, // 'localhost'
    port: process.env.DB_PORT, // 5432
    dialect: 'postgres',
    logging: false, // Desactiva el log de SQL en la consola para no saturar
    pool: {
      max: 5,
      min: 0,
      acquire: 30000,
      idle: 10000
    }
  }
);

// Función para probar la conexión
async function connectDB() {
  try {
    await sequelize.authenticate();
    console.log('✅ Conexión a PostgreSQL establecida correctamente.');
  } catch (error) {
    console.error('❌ Error al conectar con la base de datos:', error);
    // Opcional: Terminar el proceso si la conexión falla
    process.exit(1); 
  }
}

module.exports = {
  sequelize,
  connectDB
};