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
            // Asumimos que valida contra la tabla Paciente
            references: {
                model: 'Paciente', 
                key: 'cedula'
            }
        },
        diagnostico_definitivo: {
            type: DataTypes.TEXT,
            allowNull: false
        }
    }, {
        tableName: 'Diagnostico', // Aseguramos que coincida con tu tabla en Postgres
        timestamps: false // Asumo que no tienes created_at/updated_at en esta tabla específica
    });

    return Diagnostico;
};