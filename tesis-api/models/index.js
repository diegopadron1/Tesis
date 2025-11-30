const config = require("../config/db.config.js");
const Sequelize = require("sequelize");

const poolConfig = config.pool || {
  max: 5,
  min: 0,
  acquire: 30000,
  idle: 10000
};

const dbDialect = config.dialect || 'postgres';
const dbHost = config.HOST || 'localhost';

const sequelize = new Sequelize(
  config.DB,
  config.USER,
  config.PASSWORD,
  {
    host: dbHost,
    dialect: dbDialect,
    pool: {
      max: poolConfig.max,
      min: poolConfig.min,
      acquire: poolConfig.acquire,
      idle: poolConfig.idle
    },
    logging: false 
  }
);

const db = {};

db.Sequelize = Sequelize;
db.sequelize = sequelize;

db.connectDB = async () => {
    try {
        await sequelize.authenticate();
        console.log('✅ Conexión a PostgreSQL establecida correctamente.');
        await sequelize.sync({ alter: true }); 
        console.log('✅ Base de datos sincronizada.');
    } catch (error) {
        console.error('❌ Error fatal: No se pudo conectar a la base de datos:', error);
        process.exit(1);
    }
};

// ==========================================
// 2. IMPORTACIÓN DE MODELOS
// ==========================================

db.user = require("./Usuario.js")(sequelize, Sequelize);
db.role = require("./Rol.js")(sequelize, Sequelize);

// Módulos Clínicos
db.Paciente = require("./Paciente.js")(sequelize, Sequelize);
db.ContactoEmergencia = require("./ContactoEmergencia.js")(sequelize, Sequelize);
db.MotivoConsulta = require("./MotivoConsulta.js")(sequelize, Sequelize);
db.Diagnostico = require("./Diagnostico.js")(sequelize, Sequelize);
db.ExamenFisico = require("./ExamenFisico.js")(sequelize, Sequelize);
db.ExamenFuncional = require("./ExamenFuncional.js")(sequelize, Sequelize);

// Antecedentes
db.AntecedentesPersonales = require("./AntecedentesPersonales.js")(sequelize, Sequelize);
db.AntecedentesFamiliares = require("./AntecedentesFamiliares.js")(sequelize, Sequelize);
db.HabitosPsicobiologicos = require("./HabitosPsicobiologicos.js")(sequelize, Sequelize);

// Farmacia
db.Medicamento = require("./Medicamento.js")(sequelize, Sequelize);
db.MovimientoInventario = require("./MovimientoInventario.js")(sequelize, Sequelize);

// Órdenes Médicas
db.OrdenesMedicas = require("./OrdenesMedicas.js")(sequelize, Sequelize);
db.SolicitudMedicamento = require("./SolicitudMedicamento.js")(sequelize, Sequelize);


// ==========================================
// 3. DEFINICIÓN DE RELACIONES
// ==========================================

// --- CORRECCIÓN CRÍTICA AQUÍ ---
// Cambiamos belongsToMany por hasMany/belongsTo para que coincida con tu lógica de 'id_rol'
db.role.hasMany(db.user, { foreignKey: "id_rol" });
db.user.belongsTo(db.role, { foreignKey: "id_rol", as: "rol" }); // 'as: rol' es importante para el include

// Farmacia
db.Medicamento.hasMany(db.MovimientoInventario, { foreignKey: 'id_medicamento' });
db.MovimientoInventario.belongsTo(db.Medicamento, { foreignKey: 'id_medicamento' });
db.Medicamento.hasMany(db.SolicitudMedicamento, { foreignKey: 'id_medicamento' });
db.SolicitudMedicamento.belongsTo(db.Medicamento, { foreignKey: 'id_medicamento' });
db.user.hasMany(db.SolicitudMedicamento, { foreignKey: 'id_usuario' });
db.SolicitudMedicamento.belongsTo(db.user, { foreignKey: 'id_usuario' });

// Relaciones Clínicas (Tus agregados)
if (db.Paciente) {
    db.Paciente.hasOne(db.ContactoEmergencia, { foreignKey: 'cedula_paciente' });
    db.ContactoEmergencia.belongsTo(db.Paciente, { foreignKey: 'cedula_paciente' });
  
    db.Paciente.hasOne(db.MotivoConsulta, { foreignKey: 'cedula_paciente' });
    db.MotivoConsulta.belongsTo(db.Paciente, { foreignKey: 'cedula_paciente' });

    db.Paciente.hasOne(db.Diagnostico, { foreignKey: 'cedula_paciente' });
    db.Diagnostico.belongsTo(db.Paciente, { foreignKey: 'cedula_paciente' });

    db.Paciente.hasOne(db.ExamenFisico, { foreignKey: 'cedula_paciente' });
    db.ExamenFisico.belongsTo(db.Paciente, { foreignKey: 'cedula_paciente' });

    db.Paciente.hasOne(db.ExamenFuncional, { foreignKey: 'cedula_paciente' });
    db.ExamenFuncional.belongsTo(db.Paciente, { foreignKey: 'cedula_paciente' });

    db.Paciente.hasOne(db.AntecedentesPersonales, { foreignKey: 'cedula_paciente' });
    db.AntecedentesPersonales.belongsTo(db.Paciente, { foreignKey: 'cedula_paciente' });

    db.Paciente.hasOne(db.AntecedentesFamiliares, { foreignKey: 'cedula_paciente' });
    db.AntecedentesFamiliares.belongsTo(db.Paciente, { foreignKey: 'cedula_paciente' });

    db.Paciente.hasOne(db.HabitosPsicobiologicos, { foreignKey: 'cedula_paciente' });
    db.HabitosPsicobiologicos.belongsTo(db.Paciente, { foreignKey: 'cedula_paciente' });

    db.Paciente.hasMany(db.OrdenesMedicas, { foreignKey: 'cedula_paciente' });
    db.OrdenesMedicas.belongsTo(db.Paciente, { foreignKey: 'cedula_paciente' });
}

module.exports = db;