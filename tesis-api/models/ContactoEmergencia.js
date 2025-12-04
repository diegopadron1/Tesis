module.exports = (sequelize, DataTypes) => {
    const ContactoEmergencia = sequelize.define('ContactoEmergencia', {
        id_contacto: {
            type: DataTypes.INTEGER,
            primaryKey: true,
            autoIncrement: true,
            allowNull: false
        },
        cedula_paciente: { // Clave foránea
            type: DataTypes.STRING(15),
            allowNull: false,
            references: {
                model: 'Paciente', 
                key: 'cedula',
            }
        },
        nombre_apellido: { 
            type: DataTypes.STRING(200),
            allowNull: false
        },
        cedula_contacto: { 
            type: DataTypes.STRING(15),
            allowNull: true
        },
        // --- CAMBIO IMPORTANTE AQUÍ ---
        telefono: {
            type: DataTypes.STRING(20), 
            allowNull: false, 
            // Este valor por defecto rellena los registros viejos para evitar el error fatal
            defaultValue: 'No registrado' 
        },
        // ------------------------------
        parentesco: {
            type: DataTypes.STRING(50),
            allowNull: false
        }
    }, {
        tableName: 'ContactoEmergencia', 
        timestamps: false,
        freezeTableName: true 
    });

    return ContactoEmergencia;
};