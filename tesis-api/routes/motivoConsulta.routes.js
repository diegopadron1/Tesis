// routes/motivoConsulta.routes.js (CÓDIGO CORREGIDO Y LIMPIO)

const express = require('express');
const router = express.Router();
const motivoConsultaController = require('../controllers/motivoConsulta.controllers');
const { verifyToken, isResident } = require('../middlewares/authJwt'); 

// Ruta para registrar el motivo de consulta (solo Residentes)
router.post(
    '/motivo-consulta',
    verifyToken,
    isResident,
    motivoConsultaController.createMotivoConsulta
);

module.exports = router; // <-- Exporta solo el objeto router