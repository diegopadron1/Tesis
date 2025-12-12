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
        id_carpeta: {
            type: DataTypes.INTEGER,
            allowNull: false, // Ahora es obligatorio que pertenezca a una carpeta
            references: {
                model: 'carpetas', // Nombre de la tabla de carpetas
                key: 'id_carpeta'
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
        timestamps: true
    });

    return ExamenFisico;
};