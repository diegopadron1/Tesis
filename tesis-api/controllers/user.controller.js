// controllers/user.controller.js
const db = require('../models');
const Rol = db.Rol;
const Usuario = db.Usuario;
const bcrypt = require('bcryptjs');

exports.findAllRoles = async (req, res) => {
    try {
        // Solo obtener el id y el nombre del rol
        const roles = await Rol.findAll({
            attributes: ['id_rol', 'nombre_rol']
        });
        res.status(200).send(roles);
    } catch (error) {
        res.status(500).send({ message: error.message });
    }
};


exports.adminBoard = (req, res) => {
    res.status(200).send({
        message: `Bienvenido al Panel de Administrador, ${req.cedula}! Solo los administradores pueden ver esto.`,
        rol: req.rol
    });
};


exports.createUser = async (req, res) => {
    try {
        // Se asume que el request body contiene cedula, nombre, apellido, email, password e id_rol
        const { cedula, nombre, apellido, email, password, id_rol } = req.body;

        // 1. Verificar si el usuario ya existe
        const existingUser = await Usuario.findByPk(cedula);
        if (existingUser) {
            return res.status(409).send({ message: "La cédula ya está registrada." });
        }

        // 2. Hashear la contraseña antes de guardar
        const hashedPassword = bcrypt.hashSync(password, 10);

        // 3. Crear el nuevo usuario en la base de datos
        const newUser = await Usuario.create({
            cedula: cedula,
            nombre: nombre,
            apellido: apellido,
            email: email,
            password: hashedPassword,
            id_rol: id_rol,
            activo: true // Por defecto, activo
        });

        // 4. Respuesta de éxito (excluimos el hash de la contraseña de la respuesta)
        res.status(201).send({
            message: "Usuario creado exitosamente por el Administrador.",
            usuario: {
                cedula: newUser.cedula,
                nombre: newUser.nombre,
                apellido: newUser.apellido,
                rol: id_rol // Podríamos buscar el nombre del rol para una mejor UX
            }
        });

    } catch (error) {
        // Manejar errores de validación de Sequelize o de la base de datos
        res.status(500).send({ 
            message: error.message || "Ocurrió un error al crear el usuario." 
        });
    }
};

// controllers/user.controller.js (Añadir esta función)

exports.updateUser = async (req, res) => {
    try {
        const { cedula } = req.params; // Cédula del usuario a editar (viene de la URL)
        const { nombre, apellido, email, password, id_rol, activo } = req.body; // Datos a actualizar

        // 1. Buscar el usuario
        const usuario = await Usuario.findByPk(cedula);

        if (!usuario) {
            return res.status(404).send({ message: "Usuario no encontrado." });
        }
        
        // 2. Preparar los datos para actualizar
        const updateData = {
            nombre: nombre || usuario.nombre, // Si no viene en el body, usa el valor actual
            apellido: apellido || usuario.apellido,
            email: email || usuario.email,
            id_rol: id_rol || usuario.id_rol,
            activo: activo !== undefined ? activo : usuario.activo, // Permitir actualizar a false
        };

        // 3. Si se proporciona una nueva contraseña, hashearla
        if (password) {
            updateData.password = bcrypt.hashSync(password, 10);
        }

        // 4. Actualizar en la base de datos
        await usuario.update(updateData);

        // 5. Respuesta de éxito
        res.status(200).send({
            message: `Usuario con cédula ${cedula} actualizado exitosamente.`,
            usuario: {
                cedula: usuario.cedula,
                nombre: updateData.nombre,
                rol: updateData.id_rol,
                activo: updateData.activo
            }
        });

    } catch (error) {
        res.status(500).send({ 
            message: error.message || "Ocurrió un error al actualizar el usuario." 
        });
    }
};

// **IMPORTANTE:** También vamos a necesitar una ruta para listar TODOS los usuarios
exports.findAllUsers = async (req, res) => {
    try {
        const usuarios = await Usuario.findAll({
            attributes: ['cedula', 'nombre', 'apellido', 'email', 'id_rol', 'activo'],
            include: [{
                model: db.Rol,
                as: 'rol',
                attributes: ['nombre_rol']
            }]
        });
        res.status(200).send(usuarios);
    } catch (error) {
        res.status(500).send({ message: error.message || "Error al obtener la lista de usuarios." });
    }
};