module.exports = (sequelize, DataTypes) => {
    const SolicitudMedicamento = sequelize.define('SolicitudMedicamento', {
        id_solicitud: {
            type: DataTypes.INTEGER,
            primaryKey: true,
            autoIncrement: true
        },
        // --- NUEVO: Vinculación con la Orden Médica (CRUCIAL) ---
        id_orden: {
            type: DataTypes.INTEGER,
            allowNull: true, 
            references: {
                model: 'OrdenesMedicas', // Asegúrate que coincida con el tableName de Ordenes
                key: 'id_orden'
            }
        },
        // --------------------------------------------------------
        cedula_paciente: {
            type: DataTypes.STRING,
            allowNull: false
        },
        id_medicamento: {
            type: DataTypes.INTEGER,
            allowNull: false
        },
        cantidad: {
            type: DataTypes.INTEGER,
            allowNull: false
        },
        // Quién hizo la solicitud (La enfermera)
        id_usuario: { 
            type: DataTypes.STRING, 
            allowNull: false
        },
        // --- NUEVO: El campo que faltaba y daba error ---
        estatus: {
            type: DataTypes.STRING,
            allowNull: false,
            defaultValue: 'PENDIENTE' // Valores posibles: 'PENDIENTE', 'LISTO', 'ENTREGADO'
        },
        // ------------------------------------------------
        fecha_solicitud: {
            type: DataTypes.DATE,
            defaultValue: DataTypes.NOW
        }
    }, {
        tableName: 'SolicitudMedicamentos',
        timestamps: false
    });

    return SolicitudMedicamento;
};