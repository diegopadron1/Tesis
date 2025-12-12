module.exports = (sequelize, DataTypes) => {
    const Diagnostico = sequelize.define('Diagnostico', {
        id_diagnostico: {
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
        descripcion: { 
            type: DataTypes.TEXT,
            allowNull: false
        },
        tipo: { 
            type: DataTypes.STRING, 
            allowNull: false
        },
        observaciones: {
            type: DataTypes.TEXT
        },
        fecha_diagnostico: {
            type: DataTypes.DATE,
            defaultValue: DataTypes.NOW
        }
    }, {
        tableName: 'Diagnosticos',
        timestamps: true
    });

    return Diagnostico;
};