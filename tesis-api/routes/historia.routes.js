const express = require('express');
const router = express.Router();
const historiaController = require('../controllers/historia.controllers');
const { verifyToken } = require('../middlewares/authJwt');

// 1. Obtener TODA la historia clínica de un paciente
router.get('/:cedula', [verifyToken], historiaController.getHistoriaClinica);

// 2. Guardar/Actualizar una sección específica (Diagnóstico, Examen, etc.)
// El frontend enviará en el body: { seccion: 'diagnostico', datos: { ... } }
router.put('/seccion/:cedula', [verifyToken], historiaController.guardarSeccion);

// 3. Editar una Orden Médica (Solo si es PENDIENTE)
router.put('/orden/:id_orden', [verifyToken], historiaController.editarOrdenMedica);

module.exports = router;