const config = require("../config/db.config.js");
const Sequelize = require("sequelize");

const poolConfig = config.pool || {
  max: 5,
  min: 0,
  acquire: 30000,
  idle: 10000
};

const sequelize = new Sequelize(
  config.DB,
  config.USER,
  config.PASSWORD,
  {
    host: config.HOST,
    dialect: config.dialect || 'postgres',
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
        console.log('✅ Conexión a PostgreSQL establecida.');
        await sequelize.sync({ alter: true }); 
        console.log('✅ Base de datos sincronizada.');
    } catch (error) {
        console.error('❌ Error de conexión:', error);
        process.exit(1);
    }
};

// ==========================================
// IMPORTACIÓN DE MODELOS
// ==========================================

db.user = require("./Usuario.js")(sequelize, Sequelize);
db.role = require("./Rol.js")(sequelize, Sequelize);
db.Paciente = require("./Paciente.js")(sequelize, Sequelize);
db.Carpeta = require("./Carpeta.js")(sequelize, Sequelize);

// Modelos Hijos
db.MotivoConsulta = require("./MotivoConsulta.js")(sequelize, Sequelize);
db.Diagnostico = require("./Diagnostico.js")(sequelize, Sequelize);
db.ExamenFisico = require("./ExamenFisico.js")(sequelize, Sequelize);
db.ExamenFuncional = require("./ExamenFuncional.js")(sequelize, Sequelize);
db.OrdenesMedicas = require("./OrdenesMedicas.js")(sequelize, Sequelize);
db.AntecedentesPersonales = require("./AntecedentesPersonales.js")(sequelize, Sequelize);
db.AntecedentesFamiliares = require("./AntecedentesFamiliares.js")(sequelize, Sequelize);
db.HabitosPsicobiologicos = require("./HabitosPsicobiologicos.js")(sequelize, Sequelize);
db.ContactoEmergencia = require("./ContactoEmergencia.js")(sequelize, Sequelize);

// --- AGREGADO: NUEVO MODELO DE TRIAJE ---
db.Triaje = require("./Triaje.js")(sequelize, Sequelize);
// ----------------------------------------

// Farmacia
db.Medicamento = require("./Medicamento.js")(sequelize, Sequelize);
db.MovimientoInventario = require("./MovimientoInventario.js")(sequelize, Sequelize);
db.SolicitudMedicamento = require("./SolicitudMedicamento.js")(sequelize, Sequelize);


// ==========================================
// DEFINICIÓN DE RELACIONES
// ==========================================

// Roles y Usuarios
db.role.hasMany(db.user, { foreignKey: "id_rol" });
db.user.belongsTo(db.role, { foreignKey: "id_rol", as: "rol" });

// --- RELACIONES CLÍNICAS ---

if (db.Paciente && db.Carpeta) {
    // 1. Relación Paciente <-> Carpeta
    db.Paciente.hasMany(db.Carpeta, { 
        foreignKey: 'cedula_paciente', 
        sourceKey: 'cedula',
        as: 'listado_carpetas'
    });
    db.Carpeta.belongsTo(db.Paciente, { 
        foreignKey: 'cedula_paciente', 
        targetKey: 'cedula',
        as: 'paciente'
    });

    // 2. Relación Carpeta con Médico
    if (db.user) {
        db.Carpeta.belongsTo(db.user, { foreignKey: 'id_usuario', as: 'medico' });
        db.user.hasMany(db.Carpeta, { foreignKey: 'id_usuario' });
    }

    // 3. Paciente <-> Contacto
    db.Paciente.hasOne(db.ContactoEmergencia, { foreignKey: 'cedula_paciente' });
    db.ContactoEmergencia.belongsTo(db.Paciente, { foreignKey: 'cedula_paciente' });

    // 4. Paciente <-> Triaje (Relación 1 a Muchos, un paciente puede tener varios triajes en el tiempo)
    if (db.Triaje) {
        db.Paciente.hasMany(db.Triaje, { foreignKey: 'cedula_paciente' });
        db.Triaje.belongsTo(db.Paciente, { foreignKey: 'cedula_paciente' });
    }

    // 5. Carpeta <-> Hijos (Motivo, Diagnóstico, etc.)
    db.Carpeta.hasOne(db.MotivoConsulta, { foreignKey: 'id_carpeta' });
    db.MotivoConsulta.belongsTo(db.Carpeta, { foreignKey: 'id_carpeta' });

    db.Carpeta.hasOne(db.Diagnostico, { foreignKey: 'id_carpeta' });
    db.Diagnostico.belongsTo(db.Carpeta, { foreignKey: 'id_carpeta' });

    db.Carpeta.hasOne(db.ExamenFisico, { foreignKey: 'id_carpeta' });
    db.ExamenFisico.belongsTo(db.Carpeta, { foreignKey: 'id_carpeta' });
    
    db.Carpeta.hasOne(db.ExamenFuncional, { foreignKey: 'id_carpeta' });
    db.ExamenFuncional.belongsTo(db.Carpeta, { foreignKey: 'id_carpeta' });

    db.Carpeta.hasMany(db.OrdenesMedicas, { foreignKey: 'id_carpeta' });
    db.OrdenesMedicas.belongsTo(db.Carpeta, { foreignKey: 'id_carpeta' });

    db.Carpeta.hasOne(db.AntecedentesPersonales, { foreignKey: 'id_carpeta' });
    db.AntecedentesPersonales.belongsTo(db.Carpeta, { foreignKey: 'id_carpeta' });

    db.Carpeta.hasOne(db.AntecedentesFamiliares, { foreignKey: 'id_carpeta' });
    db.AntecedentesFamiliares.belongsTo(db.Carpeta, { foreignKey: 'id_carpeta' });

    db.Carpeta.hasOne(db.HabitosPsicobiologicos, { foreignKey: 'id_carpeta' });
    db.HabitosPsicobiologicos.belongsTo(db.Carpeta, { foreignKey: 'id_carpeta' });

    // ==========================================
    // 6. RELACIONES DE FARMACIA Y ÓRDENES (NUEVAS)
    // ==========================================
    
    db.OrdenesMedicas.belongsTo(db.Paciente, { foreignKey: 'cedula_paciente', targetKey: 'cedula' });
    db.Paciente.hasMany(db.OrdenesMedicas, { foreignKey: 'cedula_paciente', sourceKey: 'cedula' });

    // Vincular Órdenes con Medicamentos (Para ver el nombre del fármaco recetado)
    db.OrdenesMedicas.belongsTo(db.Medicamento, { foreignKey: 'id_medicamento', as: 'medicamento' });
    db.Medicamento.hasMany(db.OrdenesMedicas, { foreignKey: 'id_medicamento' });
    // -----------------------------------------------------------------------------

    // Vincular Órdenes con Solicitudes para trazabilidad
    if (db.OrdenesMedicas && db.SolicitudMedicamento) {
        db.OrdenesMedicas.hasMany(db.SolicitudMedicamento, { foreignKey: 'id_orden', as: 'solicitudes' });
        db.SolicitudMedicamento.belongsTo(db.OrdenesMedicas, { foreignKey: 'id_orden' });
    }

    // Vincular Solicitudes con el Inventario para saber qué se pidió
    if (db.SolicitudMedicamento && db.Medicamento) {
        db.SolicitudMedicamento.belongsTo(db.Medicamento, { foreignKey: 'id_medicamento', as: 'medicamento' });
        db.Medicamento.hasMany(db.SolicitudMedicamento, { foreignKey: 'id_medicamento' });
    }
}

module.exports = db;