module.exports = (sequelize, DataTypes) => {
    const AntecedentesFamiliares = sequelize.define('AntecedentesFamiliares', {
        id_familiar: {
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
        tipo_familiar: { // Ej: "Madre", "Padre", "Abuelo"
            type: DataTypes.STRING,
            allowNull: false
        },
        vivo_muerto: { // Ej: "Vivo" o "Muerto"
            type: DataTypes.STRING,
            allowNull: false
        },
        edad: {
            type: DataTypes.INTEGER,
            allowNull: true // Puede no saberse
        },
        patologias: {
            type: DataTypes.TEXT,
            allowNull: true
        }
    }, {
        tableName: 'AntecedentesFamiliares',
        timestamps: false
    });

    return AntecedentesFamiliares;
};