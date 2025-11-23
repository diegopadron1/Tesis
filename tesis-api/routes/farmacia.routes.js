const express = require('express');
const router = express.Router();
const farmaciaController = require('../controllers/farmacia.controllers');
const { verifyToken } = require('../middlewares/authJwt');

// Ver inventario (GET)
router.get('/inventario', [verifyToken], farmaciaController.getAllMedicamentos);

// Crear nuevo medicamento en catálogo (POST)
router.post('/medicamento', [verifyToken], farmaciaController.createMedicamento);

// Agregar Stock / Entrada (POST)
router.post('/stock/entrada', [verifyToken], farmaciaController.addStock);

// Quitar Stock / Salida (POST) - NUEVA RUTA
router.post('/stock/salida', [verifyToken], farmaciaController.removeStock);

module.exports = router;