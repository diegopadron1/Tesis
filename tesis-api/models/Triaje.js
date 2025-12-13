module.exports = (sequelize, DataTypes) => {
    const Triaje = sequelize.define('Triaje', {
        id_triaje: {
            type: DataTypes.INTEGER,
            primaryKey: true,
            autoIncrement: true
        },
        cedula_paciente: {
            type: DataTypes.STRING(15),
            allowNull: false,
            references: {
                model: 'Paciente',
                key: 'cedula'
            }
        },
        // Sistema de color (Urgencia)
        color: {
            type: DataTypes.ENUM('Rojo', 'Naranja', 'Amarillo', 'Verde', 'Azul'),
            allowNull: false,
            defaultValue: 'Verde'
        },
        // --- ZONAS ESPECÍFICAS AGREGADAS ---
        ubicacion: {
            type: DataTypes.ENUM(
                'Pasillo 1', 
                'Pasillo 2', 
                'Quirofanito paciente delicados', 
                'Trauma shock', 
                'Sillas', 
                'Libanes', 
                'USAV'
            ),
            allowNull: false,
            defaultValue: 'Sillas' // Valor por defecto seguro
        },
        // -----------------------------------
        motivo_ingreso: {
            type: DataTypes.TEXT,
            allowNull: true
        },
        signos_vitales: {
            type: DataTypes.STRING(255), // Ej: "TA: 120/80, FC: 80"
            allowNull: true
        },
        estado: {
            type: DataTypes.ENUM('En Espera', 'En Atención', 'Observación', 'Alta', 'Hospitalizado'),
            defaultValue: 'En Espera'
        }
    }, {
        tableName: 'Triaje',
        freezeTableName: true,
        timestamps: true 
    });

    return Triaje;
};