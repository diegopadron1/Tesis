const express = require('express');
const router = express.Router();
const controller = require("../controllers/reporte.controller");
const { verifyToken } = require("../middlewares/authJwt");

// Ruta para el reporte de pacientes del día
router.get('/reportes/pacientes', [verifyToken], controller.getReportePacientesPorDia);


module.exports = router;