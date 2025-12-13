const express = require('express');
const router = express.Router();
const controller = require("../controllers/triaje.controller");
const { verifyToken } = require("../middlewares/authJwt"); // O la ruta correcta de tu middleware

// Registrar un nuevo triaje
router.post('/triaje', [verifyToken], controller.createTriaje);

// Obtener triaje por cédula
router.get('/triaje/:cedula', [verifyToken], controller.getTriajeByCedula);

module.exports = router;