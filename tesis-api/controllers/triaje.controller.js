const db = require('../models');
// Intentamos cargar el modelo con mayúscula o minúscula para evitar errores de nombre
const Triaje = db.Triaje || db.triaje; 
const Paciente = db.paciente || db.Paciente;

// Registrar un nuevo Triaje
exports.createTriaje = async (req, res) => {
    try {
        // 0. Validación de seguridad: ¿El modelo cargó?
        if (!Triaje) {
            console.error("Error Crítico: El modelo 'Triaje' no está cargado en db.");
            return res.status(500).send({ message: "Error interno: El modelo Triaje no existe en la base de datos." });
        }

        const { cedula_paciente, color, ubicacion, motivo_ingreso, signos_vitales } = req.body;

        // 1. Validar que el paciente exista
        const pacienteExistente = await db.sequelize.query(
            `SELECT cedula FROM "Paciente" WHERE cedula = :cedula`,
            { replacements: { cedula: cedula_paciente }, type: db.sequelize.QueryTypes.SELECT }
        );

        if (!pacienteExistente || pacienteExistente.length === 0) {
            return res.status(404).send({ message: "Paciente no encontrado. Regístrelo primero." });
        }

        // 2. Crear el registro
        const nuevoTriaje = await Triaje.create({
            cedula_paciente,
            color,
            ubicacion,
            motivo_ingreso,
            signos_vitales,
            estado: 'En Espera'
        });

        res.status(201).send({ 
            message: "Triaje y Zona asignados correctamente.", 
            data: nuevoTriaje 
        });

    } catch (error) {
        console.error("Error en createTriaje:", error);
        // CAMBIO AQUÍ: Enviamos el mensaje real del error para que lo veas en la App
        res.status(500).send({ message: "Error DB: " + error.message });
    }
};

// Obtener el último triaje de un paciente
exports.getTriajeByCedula = async (req, res) => {
    try {
        if (!Triaje) return res.status(500).send({ message: "Modelo Triaje no cargado" });

        const { cedula } = req.params;
        const triaje = await Triaje.findOne({ 
            where: { cedula_paciente: cedula },
            order: [['createdAt', 'DESC']] // Trae el más reciente
        });

        if (!triaje) {
            return res.status(404).send({ message: "Este paciente no tiene triaje registrado." });
        }

        res.status(200).send(triaje);
    } catch (error) {
        res.status(500).send({ message: "Error: " + error.message });
    }
};