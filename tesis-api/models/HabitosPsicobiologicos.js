module.exports = (sequelize, DataTypes) => {
    const HabitosPsicobiologicos = sequelize.define('HabitosPsicobiologicos', {
        id_habito: {
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
        cafe: { type: DataTypes.STRING },
        tabaco: { type: DataTypes.STRING },
        alcohol: { type: DataTypes.STRING },
        drogas_ilicitas: { type: DataTypes.STRING },
        ocupacion: { type: DataTypes.STRING },
        sueño: { type: DataTypes.STRING }, // Sequelize maneja bien la ñ si la DB es UTF8
        vivienda: { type: DataTypes.STRING }
    }, {
        tableName: 'HabitosPsicobiologicos',
        timestamps: false
    });

    return HabitosPsicobiologicos;
};