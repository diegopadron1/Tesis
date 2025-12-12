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
        id_carpeta: {
            type: DataTypes.INTEGER,
            allowNull: false, // Ahora es obligatorio que pertenezca a una carpeta
            references: {
                model: 'carpetas', // Nombre de la tabla de carpetas
                key: 'id_carpeta'
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
        timestamps: true
    });

    return ExamenFuncional;
};