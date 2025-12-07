// models/Usuario.js
const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const Usuario = sequelize.define('Usuario', {
    cedula: {
      type: DataTypes.STRING(15),
      primaryKey: true, // La cédula es la clave principal
      allowNull: false
    },
    nombre: {
      type: DataTypes.STRING(100),
      allowNull: false
    },
    apellido: {
      type: DataTypes.STRING(100),
      allowNull: false
    },
    email: {
      type: DataTypes.STRING(150),
      allowNull: false,
      unique: true
    },
    password: {
      type: DataTypes.STRING(255), // Campo para la contraseña hasheada
      allowNull: false
    },
    activo: {
      type: DataTypes.BOOLEAN,
      defaultValue: true
    },
    id_rol: {
      type: DataTypes.INTEGER,
      allowNull: false,
      // **IMPORTANTE**: Aquí se define la clave foránea
      references: {
        model: 'Rol', // Referencia el nombre de la tabla
        key: 'id_rol'
      }
    },
    resetPasswordToken: {
    type: DataTypes.STRING,
    allowNull: true
    },
    resetPasswordExpire: {
    type: DataTypes.DATE,
    allowNull: true
    }
    // Sequelize agregará automáticamente 'creado_en' si usamos timestamps
  }, {
    tableName: 'Usuario',
    timestamps: true, // Sequelize añadirá createdAt (creado_en) y updatedAt
    createdAt: 'creado_en',
    updatedAt: 'actualizado_en'
  });

  return Usuario;
};