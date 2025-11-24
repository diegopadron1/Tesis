module.exports = (sequelize, DataTypes) => {
    const OrdenesMedicas = sequelize.define('OrdenesMedicas', {
        id_orden: {
            type: DataTypes.INTEGER,
            primaryKey: true,
            autoIncrement: true
        },
        cedula_paciente: {
            type: DataTypes.STRING,
            allowNull: false,
            references: {
                model: 'Paciente',
                key: 'cedula'
            }
        },
        // --- Campos del Médico ---
        indicaciones_inmediatas: { type: DataTypes.TEXT },
        tratamientos_sugeridos: { type: DataTypes.TEXT },
        requerimiento_medicamentos: { type: DataTypes.TEXT },
        examenes_complementarios: { type: DataTypes.TEXT },
        conducta_seguir: { type: DataTypes.TEXT },
        
        // --- Campos de Enfermería ---
        estatus: { 
            type: DataTypes.STRING,
            defaultValue: 'PENDIENTE' 
        },
        observaciones_cumplimiento: { type: DataTypes.TEXT },
        
        fecha_orden: {
            type: DataTypes.DATE,
            defaultValue: DataTypes.NOW
        },
        fecha_cumplimiento: {
            type: DataTypes.DATE
        }
    }, {
        tableName: 'OrdenesMedicas',
        timestamps: false
    });

    return OrdenesMedicas;
};