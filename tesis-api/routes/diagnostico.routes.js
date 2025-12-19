const express = require('express');
const router = express.Router();
const diagnosticoController = require('../controllers/diagnostico.controllers');
const { verifyToken, isResident } = require('../middlewares/authJwt');

// Ruta: POST /api/diagnostico
router.post(
    '/diagnostico',
    [verifyToken, isResident], // Middleware de seguridad
    diagnosticoController.createDiagnostico
);

// ACTUALIZAR (PUT) - NUEVA
router.put('/diagnostico/:id', [verifyToken, isResident], diagnosticoController.updateDiagnostico);

// Obtener diagnósticos de un paciente
router.get('/diagnostico/hoy/:cedula', [verifyToken, isResident], diagnosticoController.getDiagnosticoHoy);

module.exports = router;