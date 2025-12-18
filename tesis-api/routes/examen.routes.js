const express = require('express');
const router = express.Router();
const examenController = require('../controllers/examen.controllers');
const { verifyToken, isResident } = require('../middlewares/authJwt');

// Rutas protegidas para residentes

// --- 1. CREAR (POST) ---
router.post('/examen/fisico', [verifyToken, isResident], examenController.createExamenFisico);
router.post('/examen/funcional', [verifyToken, isResident], examenController.createExamenFuncional);

// --- 2. ACTUALIZAR (PUT) - ¡ESTAS SON LAS NUEVAS! ---
router.put(
    '/examen/fisico/:id', // Recibe el ID (ej: /api/examen/fisico/45)
    [verifyToken, isResident], 
    examenController.updateExamenFisico
);

router.put(
    '/examen/funcional/:id', // Recibe el ID (ej: /api/examen/funcional/45)
    [verifyToken, isResident], 
    examenController.updateExamenFuncional
);

module.exports = router;