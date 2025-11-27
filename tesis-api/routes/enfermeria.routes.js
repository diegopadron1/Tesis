const express = require('express');
const router = express.Router();
const enfermeriaController = require('../controllers/enfermeria.controllers');
const { verifyToken } = require('../middlewares/authJwt'); 
// Podrías crear un middleware isNurse si quieres ser estricto

// Ver todas las órdenes pendientes (Para el Dashboard)
router.get('/ordenes/pendientes', [verifyToken], enfermeriaController.getOrdenesPendientes);

// Solicitar medicamento (Descuenta inventario)
router.post('/solicitar', [verifyToken], enfermeriaController.solicitarMedicamento);

router.put('/ordenes/:id_orden', [verifyToken], enfermeriaController.actualizarEstatusOrden);

module.exports = router;