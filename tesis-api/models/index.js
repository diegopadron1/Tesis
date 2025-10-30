// models/index.js
const { sequelize, connectDB } = require('../config/db.config');
const { Sequelize, DataTypes } = require('sequelize');
const db = {};

db.sequelize = sequelize;
db.connectDB = connectDB;

// 1. Importar Modelos
db.Rol = require('./rol')(sequelize, DataTypes);
db.Usuario = require('./Usuario')(sequelize, DataTypes);
// ... aquí importaremos más modelos como Paciente, Triaje, etc. ...

// 2. Definir Relaciones (Associations)
// Un Rol tiene muchos Usuarios
db.Rol.hasMany(db.Usuario, {
  foreignKey: 'id_rol',
  as: 'usuarios'
});
// Un Usuario pertenece a un Rol
db.Usuario.belongsTo(db.Rol, {
  foreignKey: 'id_rol',
  as: 'rol'
});

module.exports = db;