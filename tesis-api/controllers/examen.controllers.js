const db = require('../models');
const ExamenFisico = db.ExamenFisico;
const ExamenFuncional = db.ExamenFuncional;

// --- CREAR EXAMEN FÍSICO ---
exports.createExamenFisico = async (req, res) => {
    const { cedula_paciente, area, hallazgos } = req.body;

    if (!cedula_paciente || !area || !hallazgos) {
        return res.status(400).send({ message: 'Faltan datos: Cédula, Área o Hallazgos.' });
    }

    try {
        const nuevoFisico = await ExamenFisico.create({
            cedula_paciente,
            area,
            hallazgos
        });
        res.status(201).send({ message: 'Examen Físico registrado.', data: nuevoFisico });
    } catch (error) {
        console.error(error);
        res.status(500).send({ message: 'Error al registrar examen físico.' });
    }
};

// --- CREAR EXAMEN FUNCIONAL ---
exports.createExamenFuncional = async (req, res) => {
    const { cedula_paciente, sistema, hallazgos } = req.body;

    if (!cedula_paciente || !sistema || !hallazgos) {
        return res.status(400).send({ message: 'Faltan datos: Cédula, Sistema o Hallazgos.' });
    }

    try {
        const nuevoFuncional = await ExamenFuncional.create({
            cedula_paciente,
            sistema,
            hallazgos
        });
        res.status(201).send({ message: 'Examen Funcional registrado.', data: nuevoFuncional });
    } catch (error) {
        console.error(error);
        res.status(500).send({ message: 'Error al registrar examen funcional.' });
    }
};