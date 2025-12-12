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
        id_carpeta: {
            type: DataTypes.INTEGER,
            allowNull: false, // Ahora es obligatorio que pertenezca a una carpeta
            references: {
                model: 'carpetas', // Nombre de la tabla de carpetas
                key: 'id_carpeta'
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
        timestamps: true
    });

    return AntecedentesPersonales;
};