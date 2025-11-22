const db = require('../models');
const AntecedentesPersonales = db.AntecedentesPersonales;
const AntecedentesFamiliares = db.AntecedentesFamiliares;
const HabitosPsicobiologicos = db.HabitosPsicobiologicos;

// 1. Crear Antecedente Personal
exports.createPersonal = async (req, res) => {
    try {
        const { cedula_paciente, tipo, detalle } = req.body;
        if (!cedula_paciente || !tipo || !detalle) {
            return res.status(400).send({ message: "Faltan datos obligatorios." });
        }
        const nuevo = await AntecedentesPersonales.create({ cedula_paciente, tipo, detalle });
        res.status(201).send({ message: "Antecedente Personal registrado.", data: nuevo });
    } catch (error) {
        res.status(500).send({ message: error.message || "Error al registrar antecedente personal." });
    }
};

// 2. Crear Antecedente Familiar
exports.createFamiliar = async (req, res) => {
    try {
        const { cedula_paciente, tipo_familiar, vivo_muerto, edad, patologias } = req.body;
        if (!cedula_paciente || !tipo_familiar || !vivo_muerto) {
            return res.status(400).send({ message: "Faltan datos obligatorios." });
        }
        const nuevo = await AntecedentesFamiliares.create({ 
            cedula_paciente, tipo_familiar, vivo_muerto, edad, patologias 
        });
        res.status(201).send({ message: "Antecedente Familiar registrado.", data: nuevo });
    } catch (error) {
        res.status(500).send({ message: error.message || "Error al registrar antecedente familiar." });
    }
};

// 3. Crear Hábitos Psicobiológicos
exports.createHabitos = async (req, res) => {
    try {
        // En este caso, muchos campos pueden ser opcionales o "Niega", pero la cédula es obligatoria
        const { cedula_paciente, cafe, tabaco, alcohol, drogas_ilicitas, ocupacion, sueño, vivienda } = req.body;
        
        if (!cedula_paciente) {
            return res.status(400).send({ message: "La cédula del paciente es obligatoria." });
        }

        const nuevo = await HabitosPsicobiologicos.create({
            cedula_paciente, cafe, tabaco, alcohol, drogas_ilicitas, ocupacion, sueño, vivienda
        });
        res.status(201).send({ message: "Hábitos registrados.", data: nuevo });
    } catch (error) {
        res.status(500).send({ message: error.message || "Error al registrar hábitos." });
    }
};