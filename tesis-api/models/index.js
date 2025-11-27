// models/index.js
const config = require("../config/db.config.js");
const Sequelize = require("sequelize");

// 1. VALIDACIONES DE SEGURIDAD
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

// Función de conexión
db.connectDB = async () => {
    try {
        await sequelize.authenticate();
        console.log('✅ Conexión a PostgreSQL establecida correctamente.');
        await sequelize.sync(); 
        console.log('✅ Base de datos sincronizada.');
    } catch (error) {
        console.error('❌ Error fatal: No se pudo conectar a la base de datos:', error);
        process.exit(1);
    }
};

// ==========================================
// 2. IMPORTACIÓN DE MODELOS
// ==========================================

// --- Autenticación ---
db.user = require("./Usuario.js")(sequelize, Sequelize);

// CORREGIDO: Usamos Rol.js (Mayúscula)
db.role = require("./Rol.js")(sequelize, Sequelize);

// Módulos Clínicos
db.Paciente = require("./Paciente.js")(sequelize, Sequelize);
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

// Solicitud de Medicamentos
db.SolicitudMedicamento = require("./SolicitudMedicamento.js")(sequelize, Sequelize);


// ==========================================
// 3. DEFINICIÓN DE RELACIONES
// ==========================================

// Roles y Usuarios
db.role.belongsToMany(db.user, { through: "user_roles" });
db.user.belongsToMany(db.role, { through: "user_roles" });

// Relaciones Farmacia
db.Medicamento.hasMany(db.MovimientoInventario, { foreignKey: 'id_medicamento' });
db.MovimientoInventario.belongsTo(db.Medicamento, { foreignKey: 'id_medicamento' });

// Relaciones Clínicas
if (db.Paciente && db.OrdenesMedicas) {
  db.Paciente.hasMany(db.OrdenesMedicas, { foreignKey: 'cedula_paciente' });
  db.OrdenesMedicas.belongsTo(db.Paciente, { foreignKey: 'cedula_paciente' });
}

// Relación Solicitud -> Medicamento
db.Medicamento.hasMany(db.SolicitudMedicamento, { foreignKey: 'id_medicamento' });
db.SolicitudMedicamento.belongsTo(db.Medicamento, { foreignKey: 'id_medicamento' });

// Relación Solicitud -> Usuario (Enfermera)
db.user.hasMany(db.SolicitudMedicamento, { foreignKey: 'id_usuario' });
db.SolicitudMedicamento.belongsTo(db.user, { foreignKey: 'id_usuario' });


module.exports = db;