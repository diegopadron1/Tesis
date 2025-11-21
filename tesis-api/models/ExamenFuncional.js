module.exports = (sequelize, DataTypes) => {
    const ExamenFuncional = sequelize.define('ExamenFuncional', {
        id_examen: { // Nota: Usaste id_examen en esta tabla según tu esquema
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
        sistema: {
            type: DataTypes.STRING, // Ej: "Respiratorio", "Cardiovascular"
            allowNull: false
        },
        hallazgos: {
            type: DataTypes.TEXT,
            allowNull: false
        }
    }, {
        tableName: 'ExamenFuncional',
        timestamps: false
    });

    return ExamenFuncional;
};