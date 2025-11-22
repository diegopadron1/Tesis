const express = require('express');
const router = express.Router();
const antecedentesController = require('../controllers/antecedentes.controllers');
const { verifyToken, isResident } = require('../middlewares/authJwt');

// Rutas protegidas
router.post('/antecedentes/personal', [verifyToken, isResident], antecedentesController.createPersonal);
router.post('/antecedentes/familiar', [verifyToken, isResident], antecedentesController.createFamiliar);
router.post('/antecedentes/habitos', [verifyToken, isResident], antecedentesController.createHabitos);

module.exports = router;