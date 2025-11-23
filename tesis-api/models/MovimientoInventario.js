module.exports = (sequelize, DataTypes) => {
    const MovimientoInventario = sequelize.define('MovimientoInventario', {
        id_movimiento: {
            type: DataTypes.INTEGER,
            primaryKey: true,
            autoIncrement: true
        },
        id_medicamento: {
            type: DataTypes.INTEGER,
            allowNull: false,
            references: {
                model: 'Medicamentos',
                key: 'id_medicamento'
            }
        },
        tipo_movimiento: {
            type: DataTypes.STRING, // 'ENTRADA', 'SALIDA'
            allowNull: false
        },
        cantidad: {
            type: DataTypes.INTEGER,
            allowNull: false
        },
        motivo: {
            type: DataTypes.STRING
        },
        fecha_movimiento: {
            type: DataTypes.DATE,
            defaultValue: DataTypes.NOW
        }
    }, {
        tableName: 'MovimientosInventario',
        timestamps: false
    });

    return MovimientoInventario;
};