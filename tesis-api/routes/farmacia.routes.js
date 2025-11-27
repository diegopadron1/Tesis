const express = require('express');
const router = express.Router();
const farmaciaController = require('../controllers/farmacia.controllers');
const { verifyToken, isFarmacia } = require('../middlewares/authJwt');

// GET Inventario
router.get('/inventario', [verifyToken], farmaciaController.getMedicamentos);

// POST Crear (Plural para seguir estándar REST)
router.post('/medicamentos', [verifyToken, isFarmacia], farmaciaController.crearMedicamento);

// PUT Stock (Unificado)
router.put('/medicamentos/:id/stock', [verifyToken, isFarmacia], farmaciaController.actualizarStock);

// DELETE Eliminar
router.delete('/medicamentos/:id', [verifyToken, isFarmacia], farmaciaController.eliminarMedicamento);

module.exports = router;