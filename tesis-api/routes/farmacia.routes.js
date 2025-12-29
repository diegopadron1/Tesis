const express = require('express');
const router = express.Router();
const farmaciaController = require('../controllers/farmacia.controllers');
const { verifyToken, isFarmacia } = require('../middlewares/authJwt');

// GET Inventario
router.get('/inventario', [verifyToken], farmaciaController.getMedicamentos);

// BUSCADOR PARA AUTOCOMPLETE (Debe ir antes de las rutas con :id)
router.get('/medicamentos/search', [verifyToken], farmaciaController.searchMedicamentos);

// POST Crear
router.post('/medicamentos', [verifyToken, isFarmacia], farmaciaController.crearMedicamento);

// PUT Stock
router.put('/medicamentos/:id/stock', [verifyToken, isFarmacia], farmaciaController.actualizarStock);

// DELETE Eliminar
router.delete('/medicamentos/:id', [verifyToken, isFarmacia], farmaciaController.eliminarMedicamento);

module.exports = router;