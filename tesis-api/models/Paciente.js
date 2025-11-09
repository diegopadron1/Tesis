// models/Paciente.js
module.exports = (sequelize, DataTypes) => {
    const Paciente = sequelize.define('Paciente', {
        cedula: {
            type: DataTypes.STRING(15),
            primaryKey: true,
            allowNull: false,
            unique: true
        },
        nombre_apellido: { // Campo único para nombre y apellido juntos
            type: DataTypes.STRING(200),
            allowNull: false
        },
        edad: { // Campo calculado por el controlador
            type: DataTypes.INTEGER,
            allowNull: false
        },
        telefono: {
            type: DataTypes.STRING(15),
            allowNull: false
        },
        fecha_nacimiento: {
            type: DataTypes.DATEONLY,
            allowNull: false
        },
        lugar_nacimiento: { 
            type: DataTypes.STRING(100),
            allowNull: true
        },
        direccion_actual: {
            type: DataTypes.STRING(100),
            allowNull: false
        },
        Estado_civil: { // Respetando la capitalización de la columna en DB
            type: DataTypes.STRING(50),
            allowNull: true
        },
        Religion: { // Respetando la capitalización de la columna en DB
            type: DataTypes.STRING(50),
            allowNull: true
        }
    }, {
        tableName: 'Paciente', 
        timestamps: false,
        freezeTableName: true 
    });

    return Paciente;
};