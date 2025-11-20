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

module.exports = router;