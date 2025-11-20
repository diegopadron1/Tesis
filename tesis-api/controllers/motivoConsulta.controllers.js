// controllers/motivoConsulta.controllers.js

const db = require('../models');
const MotivoConsulta = db.MotivoConsulta;
// const Paciente = db.Paciente; // Podrías usarlo para verificar que el paciente exista

exports.createMotivoConsulta = async (req, res) => {
    console.log("Intentando crear Motivo de Consulta...");
    // 1. Validar la entrada (aunque es básica, es buena práctica)
    const { cedula_paciente, motivo_consulta } = req.body;

    if (!cedula_paciente || !motivo_consulta) {
        return res.status(400).send({
            message: 'Debe proporcionar la cédula del paciente y el motivo de la consulta.'
        });
    }

    try {
        // 2. Crear el registro en la base de datos
        const nuevoMotivo = await MotivoConsulta.create({
            cedula_paciente: cedula_paciente,
            motivo_consulta: motivo_consulta
        });

        // 3. Respuesta exitosa
        res.status(201).send({
            message: 'Motivo de consulta registrado exitosamente.',
            data: nuevoMotivo
        });

    } catch (error) {
        // 4. Manejo de errores (por ejemplo, si la cédula no existe)
        console.error('Error al crear motivo de consulta:', error.message);
        res.status(500).send({
            message: error.message || 'Ocurrió un error interno al registrar el motivo de consulta.'
        });
    }
};

// Podrías añadir una función para obtener el historial:
// exports.getMotivosByPaciente = async (req, res) => { ... }