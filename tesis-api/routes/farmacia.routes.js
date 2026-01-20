const express = require('express');
const router = express.Router();
// Asegúrate de que el nombre del archivo coincida (controllers vs controller)
const farmaciaController = require('../controllers/farmacia.controllers'); 
const { verifyToken, isFarmacia } = require('../middlewares/authJwt');

// ==========================================
// RUTAS DE INVENTARIO
// ==========================================

// GET Inventario
router.get('/inventario', [verifyToken], farmaciaController.getMedicamentos);

// BUSCADOR PARA AUTOCOMPLETE (Debe ir antes de las rutas con :id)
router.get('/medicamentos/search', [verifyToken], farmaciaController.searchMedicamentos);

// POST Crear Medicamento
router.post('/medicamentos', [verifyToken, isFarmacia], farmaciaController.crearMedicamento);

// PUT Actualizar Stock
router.put('/medicamentos/:id/stock', [verifyToken, isFarmacia], farmaciaController.actualizarStock);

// DELETE Eliminar Medicamento
router.delete('/medicamentos/:id', [verifyToken, isFarmacia], farmaciaController.eliminarMedicamento);


// ==========================================
// RUTAS DE GESTIÓN DE SOLICITUDES (ACTUALIZADAS)
// ==========================================

// GET Ver Solicitudes (Trae PENDIENTES y LISTOS para que no desaparezcan)
router.get('/solicitudes', [verifyToken], farmaciaController.getSolicitudesPendientes);

// PUT Actualizar estado de solicitud (Botón dinámico: MARCAR LISTO / CONFIRMAR ENTREGA)
// Esta ruta sustituye a la anterior de '/solicitudes/:id/listo'
router.put('/solicitudes/:id/estado', [verifyToken], farmaciaController.actualizarEstado);

module.exports = router;