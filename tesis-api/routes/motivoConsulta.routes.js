// routes/motivoConsulta.routes.js

const express = require('express');
const router = express.Router();
const motivoConsultaController = require('../controllers/motivoConsulta.controllers');
const { verifyToken, isResident } = require('../middlewares/authJwt'); 

// 1. Ruta para registrar (POST)
router.post(
    '/motivo-consulta',
    verifyToken,
    isResident,
    motivoConsultaController.createMotivoConsulta
);

// 2. Ruta para actualizar (PUT) <--- ESTA ES LA QUE FALTABA
router.put(
    '/motivo-consulta/:id', // El :id recibirá el número (ej: 32)
    verifyToken,
    isResident,
    motivoConsultaController.updateMotivo // Asegúrate de tener esta función en tu controlador
);

module.exports = router;