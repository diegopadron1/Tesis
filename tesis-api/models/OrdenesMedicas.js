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
        id_carpeta: {
            type: DataTypes.INTEGER,
            allowNull: false, // Ahora es obligatorio que pertenezca a una carpeta
            references: {
                model: 'carpetas', // Nombre de la tabla de carpetas
                key: 'id_carpeta'
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
        timestamps: true
    });

    return OrdenesMedicas;
};