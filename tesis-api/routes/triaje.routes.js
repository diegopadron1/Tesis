const express = require('express');
const router = express.Router();
const controller = require("../controllers/triaje.controller");
const { verifyToken } = require("../middlewares/authJwt"); 

// 1. Registrar (POST)
router.post('/triaje', [verifyToken], controller.createTriaje);

// --- RUTAS ESTÁTICAS (DEBEN IR PRIMERO) ---

// 2. Listar activos (Residentes)
router.get('/triaje/activos', [verifyToken], controller.getTriajesActivos);

// 3. Listar REFERIDOS (Especialistas)
router.get('/triaje/referidos', [verifyToken], controller.getPacientesReferidos);

// ------------------------------------------

// --- RUTAS DINÁMICAS (CON :id O :cedula) ---

// 4. Actualizar estado (Genérico)
router.put('/triaje/:id/estado', [verifyToken], controller.updateEstado);

// 5. Historial por cédula
router.get('/triaje/paciente/:cedula', [verifyToken], controller.getTriajeByCedula);

// 6. Atender paciente
router.put('/triaje/atender/:id', [verifyToken], controller.atenderTriaje);

// 7. [CORREGIDA] Finalizar triaje especialista (Alta / Fallecido)
// Quitamos '/api' del inicio porque ya se incluye en server.js
// Agregamos [verifyToken] para seguridad
router.put('/triaje/finalizar/:id', [verifyToken], controller.finalizarEspecialista);

// 8. Actualizar datos generales (Esta debe ir al final para no chocar con las anteriores)
router.put('/triaje/:id', [verifyToken], controller.updateTriaje);

module.exports = router;