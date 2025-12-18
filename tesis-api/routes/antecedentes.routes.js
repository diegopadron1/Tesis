const express = require('express');
const router = express.Router();
const antecedentesController = require('../controllers/antecedentes.controllers');
const { verifyToken, isResident } = require('../middlewares/authJwt');

// Rutas CREAR (POST) - Ya las tenías
router.post('/antecedentes/personal', [verifyToken, isResident], antecedentesController.createPersonal);
router.post('/antecedentes/familiar', [verifyToken, isResident], antecedentesController.createFamiliar);
router.post('/antecedentes/habitos', [verifyToken, isResident], antecedentesController.createHabitos);

// Rutas ACTUALIZAR (PUT) - NUEVAS
router.put('/antecedentes/personal/:id', [verifyToken, isResident], antecedentesController.updatePersonal);
router.put('/antecedentes/familiar/:id', [verifyToken, isResident], antecedentesController.updateFamiliar);
router.put('/antecedentes/habitos/:id', [verifyToken, isResident], antecedentesController.updateHabitos);

module.exports = router;