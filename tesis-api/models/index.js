// models/index.js
const { sequelize, connectDB } = require('../config/db.config');
const { Sequelize, DataTypes } = require('sequelize');
const db = {};

db.sequelize = sequelize;
db.connectDB = connectDB;

// 1. Importar Modelos
db.Rol = require('./rol')(sequelize, DataTypes);
db.Usuario = require('./Usuario')(sequelize, DataTypes);
db.Paciente = require('./Paciente')(sequelize, DataTypes); // NUEVO
db.ContactoEmergencia = require('./ContactoEmergencia')(sequelize, DataTypes); // NUEVO
db.MotivoConsulta = require('./MotivoConsulta')(sequelize, DataTypes);;

// 2. Definir Relaciones (Associations)
// --- Relaciones de Autenticación ---
db.Rol.hasMany(db.Usuario, { foreignKey: 'id_rol', as: 'usuarios' });
db.Usuario.belongsTo(db.Rol, { foreignKey: 'id_rol', as: 'rol' });

// --- Relaciones de Paciente y Contacto (AJUSTADAS A LA TESIS) ---
// Un Paciente tiene un Contacto de Emergencia (1:1)
db.Paciente.hasOne(db.ContactoEmergencia, {
    foreignKey: 'cedula_paciente', // Usamos la nueva FK
    sourceKey: 'cedula', // Enlaza a la cédula del paciente
    as: 'contactoEmergencia',
    onDelete: 'CASCADE',
    onUpdate: 'CASCADE'
});

// Un Contacto de Emergencia pertenece a un Paciente
db.ContactoEmergencia.belongsTo(db.Paciente, {
    foreignKey: 'cedula_paciente', // Usamos la nueva FK
    targetKey: 'cedula', // Enlaza a la cédula del paciente
    as: 'paciente'
});

db.Paciente.hasMany(db.MotivoConsulta, { 
    foreignKey: 'cedula_paciente', 
    as: 'historialConsultas' 
});
db.MotivoConsulta.belongsTo(db.Paciente, { 
    foreignKey: 'cedula_paciente', 
    as: 'paciente' 
});


module.exports = db;