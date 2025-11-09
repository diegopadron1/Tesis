// models/Contacto_Emergencia.js
module.exports = (sequelize, DataTypes) => {
    const ContactoEmergencia = sequelize.define('ContactoEmergencia', {
        id_contacto: {
            type: DataTypes.INTEGER,
            primaryKey: true,
            autoIncrement: true,
            allowNull: false
        },
        cedula_paciente: { // Nueva clave foránea
            type: DataTypes.STRING(15),
            allowNull: false,
            references: {
                model: 'Paciente', 
                key: 'cedula',
            }
        },
        nombre_apellido: { // Campo único
            type: DataTypes.STRING(200),
            allowNull: false
        },
        cedula_contacto: { // Nueva columna
            type: DataTypes.STRING(15),
            allowNull: true // Asumo que esta cédula puede ser opcional
        },
        parentesco: {
            type: DataTypes.STRING(50),
            allowNull: false
        }
    }, {
        tableName: 'ContactoEmergencia', 
        timestamps: false,
        freezeTableName: true 
    });

    return ContactoEmergencia;
};