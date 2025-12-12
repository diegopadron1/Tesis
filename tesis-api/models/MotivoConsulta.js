// models/MotivoConsulta.js (CÓDIGO CORREGIDO Y ESTANDARIZADO)

// Exportamos una función que recibe sequelize y DataTypes
module.exports = (sequelize, DataTypes) => {
    
    // 1. Definición del Modelo
    const MotivoConsulta = sequelize.define('MotivoConsulta', {
        id_consulta: {
            type: DataTypes.INTEGER,
            primaryKey: true,
            autoIncrement: true
        },
        cedula_paciente: {
            type: DataTypes.STRING,
            allowNull: false,
            references: {
                model: 'Paciente', // Nombre real de la tabla Paciente
                key: 'cedula' // La clave primaria de la tabla Paciente
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
        motivo_consulta: {
            type: DataTypes.TEXT,
            allowNull: false
        }
    }, {
        tableName: 'MotivoConsulta',
        timestamps: true
    });

    // 2. Definición de la Asociación (Opcional, pero siguiendo la lógica anterior)
    // MotivoConsulta.associate = (models) => {
    //     models.MotivoConsulta.belongsTo(models.Paciente, { 
    //         foreignKey: 'cedula_paciente', 
    //         as: 'paciente' 
    //     });
    // };

    return MotivoConsulta;
};