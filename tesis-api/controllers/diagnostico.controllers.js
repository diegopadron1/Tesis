const db = require('../models');
const Diagnostico = db.Diagnostico;

exports.createDiagnostico = async (req, res) => {
    console.log("Intentando registrar Diagnóstico...");
    
    // 1. Validar entrada
    const { cedula_paciente, diagnostico_definitivo } = req.body;

    if (!cedula_paciente || !diagnostico_definitivo) {
        return res.status(400).send({
            message: 'Debe proporcionar la cédula del paciente y el diagnóstico definitivo.'
        });
    }

    try {
        // 2. Crear registro
        const nuevoDiagnostico = await Diagnostico.create({
            cedula_paciente: cedula_paciente,
            diagnostico_definitivo: diagnostico_definitivo
        });

        // 3. Responder éxito
        res.status(201).send({
            message: 'Diagnóstico registrado exitosamente.',
            data: nuevoDiagnostico
        });

    } catch (error) {
        console.error('Error al crear diagnóstico:', error.message);
        res.status(500).send({
            message: error.message || 'Error interno al registrar el diagnóstico.'
        });
    }
};