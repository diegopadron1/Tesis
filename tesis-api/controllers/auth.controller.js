const db = require('../models');
const config = require("../config/auth.config");
const Usuario = db.user; 
const Rol = db.role;
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
// Importamos la instancia de sequelize para usar funciones de búsqueda avanzada
const sequelize = db.sequelize; 

const crypto = require('crypto');
const nodemailer = require('nodemailer');

// Configuración del transporte de correo (GMAIL)
const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
        // --- ¡IMPORTANTE! COLOCA TUS CREDENCIALES REALES AQUÍ ---
        user: 'soporte.sistema.razetti@gmail.com', // Tu correo real
        pass: 'uxry yvtl gqai xtwg'       // Tu contraseña de aplicación de 16 letras
    }
});

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

        const token = jwt.sign(
            { 
                cedula: user.cedula,
                rol: nombreRol
            },
            config.secret,
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

// --- FUNCIÓN: OLVIDÉ MI CONTRASEÑA (Ignora mayúsculas/minúsculas) ---
exports.forgotPassword = async (req, res) => {
    try {
        const { email } = req.body;

        // 1. Buscar usuario por email (Convierte ambos a minúsculas para comparar)
        const user = await Usuario.findOne({
            where: sequelize.where(
                sequelize.fn('lower', sequelize.col('email')),
                sequelize.fn('lower', email)
            )
        });

        if (!user) {
            return res.status(404).send({ message: "No existe un usuario registrado con ese correo." });
        }

        // 2. Generar token corto (6 caracteres)
        const token = crypto.randomBytes(3).toString('hex').toUpperCase();

        // 3. Guardar token y expiración (1 hora)
        user.resetPasswordToken = token;
        user.resetPasswordExpire = Date.now() + 3600000; 
        await user.save();

        // 4. Configurar correo
        const mailOptions = {
            from: '"Soporte Tesis" <no-reply@tesis.com>',
            to: user.email, // Se envía al correo registrado en la BD
            subject: 'Código de Recuperación',
            text: `Hola ${user.nombre},\n\nTu código de recuperación es: ${token}\n\nÚsalo en la aplicación para restablecer tu contraseña.\nEste código expira en 1 hora.\n`
        };

        // 5. Enviar correo
        await transporter.sendMail(mailOptions);

        res.status(200).send({ message: "Correo de recuperación enviado exitosamente." });

    } catch (error) {
        console.error("Error en forgotPassword:", error);
        res.status(500).send({ message: "Error al enviar el correo. Verifica credenciales." });
    }
};

// --- FUNCIÓN: RESETEAR CONTRASEÑA ---
exports.resetPassword = async (req, res) => {
    try {
        const { token, newPassword } = req.body;
        const { Op } = require("sequelize");

        // Buscar usuario con ese token válido y que no haya expirado
        const user = await Usuario.findOne({
            where: {
                resetPasswordToken: token,
                resetPasswordExpire: { [Op.gt]: Date.now() }
            }
        });

        if (!user) {
            return res.status(400).send({ message: "El código de recuperación es inválido o ha expirado." });
        }

        // Encriptar nueva contraseña
        user.password = bcrypt.hashSync(newPassword, 8);
        user.resetPasswordToken = null;
        user.resetPasswordExpire = null;

        await user.save();

        res.status(200).send({ message: "Contraseña actualizada correctamente." });

    } catch (error) {
        console.error("Error en resetPassword:", error);
        res.status(500).send({ message: "Error al restablecer la contraseña." });
    }
};