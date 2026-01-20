const express = require('express');
const router = express.Router();
// CORRECCIÓN: Asegúrate que apunte al archivo singular 'farmacia.controller' que editamos
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
// RUTAS DE GESTIÓN DE SOLICITUDES (NUEVAS)
// ==========================================

// GET Ver Solicitudes Pendientes (Para la tarjeta de la App)
router.get('/solicitudes', [verifyToken, isFarmacia], farmaciaController.getSolicitudesPendientes);

// PUT Marcar Solicitud como Lista (Botón "Marcar como Preparado")
router.put('/solicitudes/:id/listo', [verifyToken, isFarmacia], farmaciaController.marcarListo);

module.exports = router;