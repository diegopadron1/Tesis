const express = require('express');
const router = express.Router();
const controller = require("../controllers/triaje.controller");
const { verifyToken } = require("../middlewares/authJwt"); 

// 1. Registrar un nuevo triaje
router.post('/triaje', [verifyToken], controller.createTriaje);

// --- NUEVAS RUTAS PARA EL TABLERO ---

// 2. Listar pacientes activos (Dashboard / Sala de Espera)
router.get('/triaje/activos', [verifyToken], controller.getTriajesActivos);

// 3. Actualizar estado (Dar de alta, Hospitalizar)
router.put('/triaje/:id/estado', [verifyToken], controller.updateEstado);

// -------------------------------------

// 4. Obtener historial de triaje por cédula
router.get('/triaje/:cedula', [verifyToken], controller.getTriajeByCedula);

// 5. Atender paciente
// CORRECCIONES AQUI:
// - Usamos 'controller' (la variable correcta).
// - Cambiamos '/triajes' a '/triaje' para coincidir con la URL base de Flutter.
// - Agregamos [verifyToken] para seguridad.
router.put('/triaje/:id/atender', [verifyToken], controller.atenderTriaje);

// Actualizar datos del triaje (PUT)
router.put('/triaje/:id', [verifyToken], controller.updateTriaje);

module.exports = router;