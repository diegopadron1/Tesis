module.exports = (sequelize, DataTypes) => {
    const SolicitudMedicamento = sequelize.define('SolicitudMedicamento', {
        id_solicitud: {
            type: DataTypes.INTEGER,
            primaryKey: true,
            autoIncrement: true
        },
        cedula_paciente: {
            type: DataTypes.STRING,
            allowNull: false
        },
        id_medicamento: {
            type: DataTypes.INTEGER,
            allowNull: false
        },
        cantidad: {
            type: DataTypes.INTEGER,
            allowNull: false
        },
        // Quién hizo la solicitud (La enfermera)
        id_usuario: { 
            type: DataTypes.STRING, // <--- CORRECCIÓN: Cambiado de INTEGER a STRING
            allowNull: false
        },
        fecha_solicitud: {
            type: DataTypes.DATE,
            defaultValue: DataTypes.NOW
        }
    }, {
        tableName: 'SolicitudMedicamentos',
        timestamps: false
    });

    return SolicitudMedicamento;
};