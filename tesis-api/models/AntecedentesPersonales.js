module.exports = (sequelize, DataTypes) => {
    const AntecedentesPersonales = sequelize.define('AntecedentesPersonales', {
        id_antecedente: {
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
        tipo: { // Ej: "Quirúrgico", "Alérgico", "Patológico"
            type: DataTypes.STRING,
            allowNull: false
        },
        detalle: {
            type: DataTypes.TEXT,
            allowNull: false
        }
    }, {
        tableName: 'AntecedentesPersonales',
        timestamps: false
    });

    return AntecedentesPersonales;
};