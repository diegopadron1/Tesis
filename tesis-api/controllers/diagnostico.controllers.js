const db = require('../models');
const Diagnostico = db.Diagnostico;
const OrdenesMedicas = db.OrdenesMedicas;
const MotivoConsulta = db.MotivoConsulta;
const ExamenFisico = db.ExamenFisico;
const AntecedentesPersonales = db.AntecedentesPersonales;

// Crear Diagnóstico y Órdenes Médicas
exports.createDiagnostico = async (req, res) => {
    const { 
        cedula_paciente, 
        descripcion, 
        tipo, 
        observaciones,
        // Campos para Órdenes Médicas
        indicaciones_inmediatas,
        tratamientos_sugeridos,
        requerimiento_medicamentos,
        examenes_complementarios,
        conducta_seguir
    } = req.body;

    if (!cedula_paciente || !descripcion || !tipo) {
        return res.status(400).send({ message: 'Faltan datos obligatorios del diagnóstico.' });
    }

    try {
        // --- 1. VALIDACIÓN DE PRERREQUISITOS CLÍNICOS (BLOQUEOS) ---
        
        // A. Motivo
        const tieneMotivo = await MotivoConsulta.findOne({ where: { cedula_paciente } });
        if (!tieneMotivo) {
            return res.status(403).send({ message: "BLOQUEO: Paciente sin Motivo de Consulta. Debe registrarlo primero." });
        }

        // B. Examen Físico
        const tieneExamen = await ExamenFisico.findOne({ where: { cedula_paciente } });
        if (!tieneExamen) {
            return res.status(403).send({ message: "BLOQUEO: Paciente sin Examen Físico. Debe realizarlo primero." });
        }

        // C. Antecedentes
        const tieneAntecedentes = await AntecedentesPersonales.findOne({ where: { cedula_paciente } });
        if (!tieneAntecedentes) {
            return res.status(403).send({ message: "BLOQUEO: Paciente sin Antecedentes. Debe interrogarlos primero." });
        }

        // --- 2. CREAR DIAGNÓSTICO (Tabla A) ---
        const nuevoDiagnostico = await Diagnostico.create({
            cedula_paciente,
            descripcion,
            tipo,
            observaciones
        });

        // --- 3. CREAR ÓRDENES MÉDICAS (Tabla B - Independiente pero vinculada al Paciente) ---
        let ordenCreada = null;
        // Solo creamos la orden si el médico escribió algo en esos campos
        if (indicaciones_inmediatas || tratamientos_sugeridos || requerimiento_medicamentos || examenes_complementarios || conducta_seguir) {
            ordenCreada = await OrdenesMedicas.create({
                cedula_paciente, // Usamos la cédula directamente
                indicaciones_inmediatas,
                tratamientos_sugeridos,
                requerimiento_medicamentos,
                examenes_complementarios,
                conducta_seguir,
                estatus: 'PENDIENTE' // Nace pendiente para enfermería
            });
        }

        res.status(201).send({ 
            message: 'Diagnóstico y Órdenes registradas correctamente.',
            diagnostico: nuevoDiagnostico,
            orden: ordenCreada
        });

    } catch (error) {
        console.error("Error en createDiagnostico:", error);
        res.status(500).send({ message: 'Error interno al procesar el diagnóstico.' });
    }
};

// Obtener diagnósticos de un paciente
exports.getDiagnosticosByPaciente = async (req, res) => {
    try {
        const { cedula } = req.params;
        // Como ya no están vinculados por ID, traemos los diagnósticos solos.
        // Si quisieras traer las órdenes, tendrías que hacer otra consulta o un include basado en la cédula (si Sequelize lo permite así, que es complejo).
        // Por ahora, devolvemos solo diagnósticos aquí.
        const diagnosticos = await Diagnostico.findAll({ 
            where: { cedula_paciente: cedula },
            order: [['fecha_diagnostico', 'DESC']]
        });
        res.status(200).send(diagnosticos);
    } catch (error) {
        res.status(500).send({ message: 'Error al obtener historial.' });
    }
};