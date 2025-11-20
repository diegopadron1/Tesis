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
        motivo_consulta: {
            type: DataTypes.TEXT,
            allowNull: false
        }
    }, {
        tableName: 'MotivoConsulta',
        timestamps: false
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