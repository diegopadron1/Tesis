const db = require('../models');
const config = require("../config/auth.config"); // <--- IMPORTAMOS LA CONFIG
const Usuario = db.user; 
const Rol = db.role;
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

// YA NO NECESITAMOS DEFINIR LA CLAVE AQUÍ
// const JWT_SECRET = ... (Borrar esta línea)

exports.signin = async (req, res) => {
    try {
        const { cedula, password } = req.body;

        const user = await Usuario.findOne({
            where: { cedula: cedula }
        });

        if (!user) {
            return res.status(404).send({ message: "Usuario no encontrado." });
        }

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

        let nombreRol = "Usuario";
        if (user.id_rol) {
            const rolEncontrado = await Rol.findByPk(user.id_rol);
            if (rolEncontrado) {
                nombreRol = rolEncontrado.nombre_rol;
            }
        }

        // USAMOS config.secret AQUÍ
        const token = jwt.sign(
            { 
                cedula: user.cedula,
                rol: nombreRol
            },
            config.secret, // <--- LA CLAVE CENTRALIZADA
            {
                expiresIn: 86400 
            }
        );

        res.status(200).send({
            cedula: user.cedula,
            nombre: user.nombre,
            apellido: user.apellido,
            email: user.email,
            rol: nombreRol,
            roles: [nombreRol],
            accessToken: token
        });

    } catch (error) {
        console.error("Error en signin:", error);
        res.status(500).send({ 
            message: error.message || "Error al iniciar sesión."
        });
    }
};