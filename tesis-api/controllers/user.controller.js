const db = require('../models');
// CORRECCIÓN: Usamos las claves exactas definidas en index.js (minúsculas)
const Rol = db.role; 
const Usuario = db.user;
const bcrypt = require('bcryptjs');

exports.findAllRoles = async (req, res) => {
    try {
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
        const { cedula, nombre, apellido, email, password, id_rol } = req.body;

        const existingUser = await Usuario.findByPk(cedula);
        if (existingUser) {
            return res.status(409).send({ message: "La cédula ya está registrada." });
        }

        const hashedPassword = bcrypt.hashSync(password, 10);

        const newUser = await Usuario.create({
            cedula: cedula,
            nombre: nombre,
            apellido: apellido,
            email: email,
            password: hashedPassword,
            id_rol: id_rol,
            activo: true 
        });

        res.status(201).send({
            message: "Usuario creado exitosamente por el Administrador.",
            usuario: {
                cedula: newUser.cedula,
                nombre: newUser.nombre,
                apellido: newUser.apellido,
                rol: id_rol 
            }
        });

    } catch (error) {
        res.status(500).send({ 
            message: error.message || "Ocurrió un error al crear el usuario." 
        });
    }
};

exports.updateUser = async (req, res) => {
    try {
        const { cedula } = req.params; 
        const { nombre, apellido, email, password, id_rol, activo } = req.body; 

        const usuario = await Usuario.findByPk(cedula);

        if (!usuario) {
            return res.status(404).send({ message: "Usuario no encontrado." });
        }
        
        const updateData = {
            nombre: nombre || usuario.nombre, 
            apellido: apellido || usuario.apellido,
            email: email || usuario.email,
            id_rol: id_rol || usuario.id_rol,
            activo: activo !== undefined ? activo : usuario.activo, 
        };

        if (password) {
            updateData.password = bcrypt.hashSync(password, 10);
        }

        await usuario.update(updateData);

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

// **IMPORTANTE:** Corrección para que funcione el listado
exports.findAllUsers = async (req, res) => {
    try {
        const usuarios = await Usuario.findAll({
            attributes: ['cedula', 'nombre', 'apellido', 'email', 'id_rol', 'activo'],
            include: [{
                model: Rol,
                as: 'rol', // Debe coincidir con el 'as' definido en index.js
                attributes: ['nombre_rol']
            }]
        });
        res.status(200).send(usuarios);
    } catch (error) {
        console.error("Error backend listando usuarios:", error); // Log para ver el error real
        res.status(500).send({ message: error.message || "Error al obtener la lista de usuarios." });
    }
};