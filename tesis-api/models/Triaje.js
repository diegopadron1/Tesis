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
        // --- ZONAS ESPECÍFICAS ---
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
            defaultValue: 'Sillas'
        },
        // -----------------------------------
        motivo_ingreso: {
            type: DataTypes.TEXT,
            allowNull: true
        },
        signos_vitales: {
            type: DataTypes.STRING(255),
            allowNull: true
        },
        // Atendido por (Doctor/Residente):
        residente_atendiendo: {
            type: DataTypes.STRING(100),
            allowNull: true
        },
        estado: {
            type: DataTypes.STRING(50), // Cambiado a STRING según tu server.js
            allowNull: false,
            defaultValue: 'En Espera'
        },
        // --- AQUÍ AGREGAMOS LA COLUMNA QUE FALTABA ---
        id_carpeta: {
            type: DataTypes.INTEGER,
            allowNull: true // Permitimos null para compatibilidad
        }
        // ---------------------------------------------
    }, {
        tableName: 'Triaje',
        freezeTableName: true,
        timestamps: true 
    });

    return Triaje;
};