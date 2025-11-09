// routes/patientRoutes.js

const express = require('express');
const router = express.Router();
const patientController = require('../controllers/patientController');
const { verifyToken, isResident } = require('../middlewares/authJwt'); // Asume este middleware de autenticación

// Ruta para registrar un nuevo paciente (accesible por Admin y Residente)
router.post(
    '/pacientes',
    verifyToken, // Asegura que el usuario esté logueado
    isResident, // Asegura que solo Admin o Residente puedan registrar
    ...patientController.validatePatientRegistration, // Valida los datos antes de ejecutar el controlador
    patientController.registerPatient
);

module.exports = router;