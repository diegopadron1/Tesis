module.exports = (sequelize, DataTypes) => {
    const ExamenFisico = sequelize.define('ExamenFisico', {
        id_fisico: {
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
        area: {
            type: DataTypes.STRING, // Ej: "Cabeza", "Tórax", "Abdomen"
            allowNull: false
        },
        hallazgos: {
            type: DataTypes.TEXT,
            allowNull: false
        }
    }, {
        tableName: 'ExamenFisico',
        timestamps: false
    });

    return ExamenFisico;
};