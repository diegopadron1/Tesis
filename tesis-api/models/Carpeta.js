module.exports = (sequelize, Sequelize) => {
    const Carpeta = sequelize.define("carpeta", {
        id_carpeta: {
            type: Sequelize.INTEGER,
            primaryKey: true,
            autoIncrement: true
        },
        fecha_creacion: {
            type: Sequelize.DATE,
            defaultValue: Sequelize.NOW
        },
        estatus: {
            type: Sequelize.STRING,
            defaultValue: "ABIERTA" // ABIERTA, CERRADA, CANCELADA
        },
        // --- CORRECCIÓN AQUÍ ---
        // Cambiamos de INTEGER a STRING para que coincida con la Cédula del usuario
        id_usuario: {
            type: Sequelize.STRING, 
            allowNull: true,
            comment: "Cédula del usuario (médico) que creó la carpeta"
        },
        atendido_por: {
            type: Sequelize.STRING,
            allowNull: true,
            comment: "Nombre textual del médico (snapshot) para mostrar en historial"
        }
    }, {
        tableName: "carpetas",
        timestamps: true 
    });

    return Carpeta;
};