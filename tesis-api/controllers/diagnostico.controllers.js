const db = require('../models');
const Diagnostico = db.Diagnostico;
const OrdenesMedicas = db.OrdenesMedicas;
const MotivoConsulta = db.MotivoConsulta;
const ExamenFisico = db.ExamenFisico;
const AntecedentesPersonales = db.AntecedentesPersonales;
const Carpeta = db.Carpeta; 
const { Op } = require("sequelize"); 

// Crear Diagnóstico y Órdenes Médicas
exports.createDiagnostico = async (req, res) => {
    console.log("Intentando crear Diagnóstico...");
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
        conducta_seguir,
        // Datos del médico (Opcional)
        id_usuario,
        atendido_por
    } = req.body;

    if (!cedula_paciente || !descripcion || !tipo) {
        return res.status(400).send({ message: 'Faltan datos obligatorios del diagnóstico.' });
    }

    try {
        // --- 1. VALIDACIÓN DE PRERREQUISITOS CLÍNICOS ---
        
        const tieneMotivo = await MotivoConsulta.findOne({ where: { cedula_paciente } });
        if (!tieneMotivo) {
            return res.status(403).send({ message: "BLOQUEO: Paciente sin Motivo de Consulta. Debe registrarlo primero." });
        }

        const tieneExamen = await ExamenFisico.findOne({ where: { cedula_paciente } });
        if (!tieneExamen) {
            return res.status(403).send({ message: "BLOQUEO: Paciente sin Examen Físico. Debe realizarlo primero." });
        }

        const tieneAntecedentes = await AntecedentesPersonales.findOne({ where: { cedula_paciente } });
        if (!tieneAntecedentes) {
            return res.status(403).send({ message: "BLOQUEO: Paciente sin Antecedentes. Debe interrogarlos primero." });
        }

        // --- 2. LÓGICA DE CARPETA INTELIGENTE ---
        const inicioDia = new Date(); inicioDia.setHours(0, 0, 0, 0);
        const finDia = new Date(); finDia.setHours(23, 59, 59, 999);

        // Buscar la ÚLTIMA carpeta de hoy
        const ultimaCarpeta = await Carpeta.findOne({
            where: {
                cedula_paciente: cedula_paciente,
                createdAt: { [Op.gte]: inicioDia, [Op.lte]: finDia }
            },
            order: [['createdAt', 'DESC']]
        });

        let carpeta;

        // Si no existe O si la última ya está de Alta -> Crear Nueva
        if (!ultimaCarpeta || ultimaCarpeta.estatus === 'Alta') {
            console.log(`📂 Creando carpeta automática (Diagnóstico) para ${cedula_paciente}...`);
            carpeta = await Carpeta.create({
                cedula_paciente: cedula_paciente,
                fecha_creacion: new Date(),
                estatus: 'ABIERTA',
                id_usuario: id_usuario || null,
                atendido_por: atendido_por || null
            });
        } else {
            // Usar la existente abierta
            carpeta = ultimaCarpeta;
        }

        // --- 3. CREAR DIAGNÓSTICO ---
        const nuevoDiagnostico = await Diagnostico.create({
            cedula_paciente,
            descripcion,
            tipo,
            observaciones,
            id_carpeta: carpeta.id_carpeta 
        });

        // --- 4. CREAR ÓRDENES MÉDICAS ---
        let ordenCreada = null;
        
        if (indicaciones_inmediatas || tratamientos_sugeridos || requerimiento_medicamentos || examenes_complementarios || conducta_seguir) {
            ordenCreada = await OrdenesMedicas.create({
                cedula_paciente, 
                indicaciones_inmediatas,
                tratamientos_sugeridos,
                requerimiento_medicamentos,
                examenes_complementarios,
                conducta_seguir,
                estatus: 'PENDIENTE',
                id_carpeta: carpeta.id_carpeta 
            });

            // --- LÓGICA DE CIERRE AUTOMÁTICO POR ALTA EN LA CONDUCTA ---
            if (conducta_seguir && conducta_seguir.toLowerCase().includes('alta')) {
                console.log(`🔒 Cerrando carpeta ID ${carpeta.id_carpeta} por Alta Médica en conducta...`);
                await Carpeta.update(
                    { estatus: 'Alta' },
                    { where: { id_carpeta: carpeta.id_carpeta } }
                );
            }
        }

        res.status(201).send({ 
            message: 'Diagnóstico y Órdenes registradas correctamente.',
            diagnostico: nuevoDiagnostico,
            orden: ordenCreada,
            id_carpeta: carpeta.id_carpeta
        });

    } catch (error) {
        console.error("Error en createDiagnostico:", error);
        res.status(500).send({ message: error.message || 'Error interno al procesar el diagnóstico.' });
    }
};

// Obtener diagnósticos de un paciente
exports.getDiagnosticosByPaciente = async (req, res) => {
    try {
        const { cedula } = req.params;
        
        const diagnosticos = await Diagnostico.findAll({ 
            where: { cedula_paciente: cedula },
            order: [['createdAt', 'DESC']] 
        });
        res.status(200).send(diagnosticos);
    } catch (error) {
        res.status(500).send({ message: 'Error al obtener historial.' });
    }
};

// ==========================================
// NUEVA FUNCIÓN DE ACTUALIZACIÓN (PUT)
// ==========================================
exports.updateDiagnostico = async (req, res) => {
    try {
        const { id } = req.params; 
        const { 
            descripcion, tipo, observaciones, 
            id_orden, 
            indicaciones_inmediatas, tratamientos_sugeridos, 
            requerimiento_medicamentos, examenes_complementarios, conducta_seguir 
        } = req.body;

        // 1. ACTUALIZAR DIAGNÓSTICO
        const diagnostico = await Diagnostico.findByPk(id);
        if (!diagnostico) return res.status(404).send({ success: false, message: "Diagnóstico no encontrado." });

        diagnostico.descripcion = descripcion;
        diagnostico.tipo = tipo;
        diagnostico.observaciones = observaciones;
        await diagnostico.save();

        // 2. ACTUALIZAR ÓRDENES MÉDICAS
        let ordenActualizada = null;
        if (id_orden) {
            const orden = await OrdenesMedicas.findByPk(id_orden);
            if (orden) {
                orden.indicaciones_inmediatas = indicaciones_inmediatas;
                orden.tratamientos_sugeridos = tratamientos_sugeridos;
                orden.requerimiento_medicamentos = requerimiento_medicamentos;
                orden.examenes_complementarios = examenes_complementarios;
                orden.conducta_seguir = conducta_seguir;
                await orden.save();
                ordenActualizada = orden;

                // --- LÓGICA DE CIERRE AUTOMÁTICO (TAMBIÉN AL ACTUALIZAR) ---
                if (conducta_seguir && conducta_seguir.toLowerCase().includes('alta')) {
                    console.log(`🔒 Cerrando carpeta ID ${orden.id_carpeta} por Alta Médica en actualización...`);
                    await Carpeta.update(
                        { estatus: 'Alta' },
                        { where: { id_carpeta: orden.id_carpeta } }
                    );
                }
            }
        }

        res.status(200).send({ 
            success: true, 
            message: "Diagnóstico y órdenes actualizados.", 
            data: { diagnostico, orden: ordenActualizada }
        });

    } catch (error) {
        console.error("Error updateDiagnostico:", error);
        res.status(500).send({ message: "Error interno: " + error.message });
    }
};

// ==========================================
// Obtener Diagnóstico y Órdenes de HOY
// ==========================================
exports.getDiagnosticoHoy = async (req, res) => {
    try {
        const { cedula } = req.params;
        const inicioDia = new Date(); inicioDia.setHours(0, 0, 0, 0);
        const finDia = new Date(); finDia.setHours(23, 59, 59, 999);

        // 1. Buscar la ÚLTIMA carpeta de hoy
        const carpeta = await Carpeta.findOne({
            where: { cedula_paciente: cedula, createdAt: { [Op.gte]: inicioDia, [Op.lte]: finDia } },
            order: [['createdAt', 'DESC']] // Importante: La más reciente
        });

        // Caso A: No existe carpeta
        if (!carpeta) {
            return res.status(200).send({ success: true, data: { diagnostico: null, orden: null } });
        }

        // --- CORRECCIÓN CLAVE AQUÍ ---
        // Caso B: Existe carpeta, pero está de 'Alta'.
        // Devolvemos NULL para que el médico pueda crear una nueva orden/diagnóstico.
        if (carpeta.estatus === 'Alta') {
            return res.status(200).send({ 
                success: true, 
                data: { diagnostico: null, orden: null } 
            });
        }
        // -----------------------------

        // 2. Buscar datos (Solo si la carpeta está ABIERTA)
        const diagnostico = await Diagnostico.findOne({ where: { id_carpeta: carpeta.id_carpeta } });
        const orden = await OrdenesMedicas.findOne({ where: { id_carpeta: carpeta.id_carpeta } });

        res.status(200).send({
            success: true,
            data: { diagnostico, orden }
        });

    } catch (error) {
        console.error(error);
        res.status(500).send({ message: "Error al obtener diagnóstico." });
    }
};