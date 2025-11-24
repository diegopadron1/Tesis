const db = require('../models');
const Usuario = db.user; 
const Rol = db.role;
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET || "clave-secreta-temporal";

exports.signin = async (req, res) => {
    try {
        const { cedula, password } = req.body;

        // 1. Buscar el usuario
        const user = await Usuario.findOne({
            where: { cedula: cedula }
        });

        if (!user) {
            return res.status(404).send({ 
                message: "Usuario no encontrado." 
            });
        }

        // 2. Comparar contraseña
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

        // 3. Obtener el nombre del Rol
        let nombreRol = "Usuario";
        if (user.id_rol) {
            const rolEncontrado = await Rol.findByPk(user.id_rol);
            if (rolEncontrado) {
                nombreRol = rolEncontrado.nombre_rol;
            }
        }

        // 4. Generar Token
        const token = jwt.sign(
            { 
                cedula: user.cedula,
                rol: nombreRol
            },
            JWT_SECRET,
            {
                expiresIn: 86400 
            }
        );

        // 5. Responder (CORRECCIÓN AQUÍ)
        // Enviamos 'rol' en singular porque así lo espera tu AuthService en Flutter
        res.status(200).send({
            cedula: user.cedula,
            nombre: user.nombre,
            apellido: user.apellido,
            email: user.email,
            rol: nombreRol,       // <--- ESTA LÍNEA ES LA CLAVE (Singular)
            roles: [nombreRol],   // Dejamos este por si acaso en el futuro lo necesitas
            accessToken: token
        });

    } catch (error) {
        console.error("Error en signin:", error);
        res.status(500).send({ 
            message: error.message || "Error al iniciar sesión."
        });
    }
};