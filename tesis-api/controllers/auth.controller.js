// controllers/auth.controller.js
const db = require('../models');
const Usuario = db.Usuario;
const Rol = db.Rol;
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

// Asegúrate de añadir una clave secreta fuerte en tu archivo .env
// Por ahora, la definiremos aquí temporalmente para avanzar. 
// ¡RECUERDA MOVER ESTO AL .ENV!
const JWT_SECRET = process.env.JWT_SECRET;

exports.signin = async (req, res) => {
    try {
        const { cedula, password } = req.body;

        // 1. Buscar el usuario por cédula
        const user = await Usuario.findOne({
            where: { cedula: cedula },
            // Incluir el nombre del Rol en la respuesta
            include: [{
                model: Rol,
                as: 'rol',
                attributes: ['nombre_rol'] 
            }]
        });

        // 2. Verificar si el usuario existe y está activo
        if (!user || !user.activo) {
            return res.status(404).send({ 
                message: "Usuario no encontrado o inactivo." 
            });
        }

        // 3. Comparar la contraseña ingresada con el hash almacenado
        const passwordIsValid = bcrypt.compareSync(
            password,
            user.password
        );

        if (!passwordIsValid) {
            return res.status(401).send({
                accessToken: null,
                message: "Contraseña incorrecta."
            });
        }

        // 4. Generar el Token JWT
        const token = jwt.sign(
            { 
                cedula: user.cedula,
                rol: user.rol.nombre_rol
            },
            JWT_SECRET,
            {
                expiresIn: 86400 // 24 horas en segundos
            }
        );

        // 5. Responder con la información del usuario y el token
        res.status(200).send({
            cedula: user.cedula,
            nombre: user.nombre,
            apellido: user.apellido,
            email: user.email,
            rol: user.rol.nombre_rol,
            accessToken: token
        });

    } catch (error) {
        res.status(500).send({ 
            message: error.message 
        });
    }
};