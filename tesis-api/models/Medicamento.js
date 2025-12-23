module.exports = (sequelize, DataTypes) => {
    const Medicamento = sequelize.define('Medicamento', {
        id_medicamento: {
            type: DataTypes.INTEGER,
            primaryKey: true,
            autoIncrement: true
        },
        nombre: {
            type: DataTypes.STRING,
            allowNull: false
        },
        principio_activo: {
            type: DataTypes.STRING
        },
        concentracion: { // Campo separado como pediste
            type: DataTypes.STRING
        },
        presentacion: {
            type: DataTypes.STRING
        },
        cantidad_disponible: {
            type: DataTypes.INTEGER,
            defaultValue: 0
        },
        stock_minimo: {
            type: DataTypes.INTEGER,
            defaultValue: 10
        },
        fecha_vencimiento: {
            type: DataTypes.DATEONLY // DATEONLY guarda solo YYYY-MM-DD
        }
    }, {
        tableName: 'Medicamentos',
        timestamps: false,
        indexes: [
            {
                unique: true,
                fields: ['nombre', 'concentracion', 'fecha_vencimiento']
            }
        ]
    });

    return Medicamento;
};