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
        id_carpeta: {
            type: DataTypes.INTEGER,
            allowNull: false, // Ahora es obligatorio que pertenezca a una carpeta
            references: {
                model: 'carpetas', // Nombre de la tabla de carpetas
                key: 'id_carpeta'
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
        timestamps: true
    });

    return AntecedentesFamiliares;
};