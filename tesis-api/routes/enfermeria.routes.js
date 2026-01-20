const express = require('express');
const router = express.Router();

// Asegúrate de que la ruta apunte al archivo que modificamos antes.
// Si tu archivo se llama "enfermeria.controller.js", usa ese nombre aquí.
const enfermeriaController = require('../controllers/enfermeria.controllers'); 
const { verifyToken } = require('../middlewares/authJwt'); 

// 1. Ver todas las órdenes pendientes (Para la lista de gestión)
router.get('/ordenes/pendientes', [verifyToken], enfermeriaController.getOrdenesPendientes);

// 2. Solicitar medicamento (Para el carrito de compras)
// Nota: En el frontend llamamos a este endpoint para cada ítem del carrito
router.post('/solicitar-medicamento', [verifyToken], enfermeriaController.solicitarMedicamento);

// 3. Actualizar estado (Suministrado / No Realizado)
router.put('/ordenes/:id_orden', [verifyToken], enfermeriaController.actualizarEstatusOrden);

// 4. Obtener orden activa para el buscador (El cuadro amarillo)
router.get('/medicamento-autorizado/:cedula', [verifyToken], enfermeriaController.getMedicamentoAutorizado);

module.exports = router;