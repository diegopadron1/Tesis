const express = require('express');
const router = express.Router();
const examenController = require('../controllers/examen.controllers');
const { verifyToken, isResident } = require('../middlewares/authJwt');

// Rutas protegidas para residentes
router.post('/examen/fisico', [verifyToken, isResident], examenController.createExamenFisico);
router.post('/examen/funcional', [verifyToken, isResident], examenController.createExamenFuncional);

module.exports = router;