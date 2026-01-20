const db = require('../models');
const Diagnostico = db.Diagnostico;
const OrdenesMedicas = db.OrdenesMedicas;
const MotivoConsulta = db.MotivoConsulta;
const ExamenFisico = db.ExamenFisico;
const AntecedentesPersonales = db.AntecedentesPersonales;
const Carpeta = db.Carpeta; 
const { Op } = require("sequelize"); 

// ==========================================
// 1. Crear Diagnóstico y Órdenes Médicas
// ==========================================
exports.createDiagnostico = async (req, res) => {
    // LOG DE DEPURACIÓN
    console.log("--- Recibiendo petición para crear Diagnóstico ---");
    console.log("Cuerpo de la petición:", req.body);

    const { 
        cedula_paciente, 
        descripcion, 
        tipo, 
        observaciones,
        // Campos para Órdenes Médicas
        id_medicamento, 
        indicaciones_inmediatas,
        tratamientos_sugeridos,
        requerimiento_medicamentos,
        examenes_complementarios,
        conducta_seguir,
        id_usuario,
        atendido_por
    } = req.body;

    if (!cedula_paciente || !descripcion || !tipo) {
        return res.status(400).send({ message: 'Faltan datos obligatorios del diagnóstico.' });
    }

    try {
        // --- VALIDACIÓN DE PRERREQUISITOS ---
        const tieneMotivo = await MotivoConsulta.findOne({ where: { cedula_paciente } });
        if (!tieneMotivo) return res.status(403).send({ message: "BLOQUEO: Paciente sin Motivo de Consulta." });

        const tieneExamen = await ExamenFisico.findOne({ where: { cedula_paciente } });
        if (!tieneExamen) return res.status(403).send({ message: "BLOQUEO: Paciente sin Examen Físico." });

        const tieneAntecedentes = await AntecedentesPersonales.findOne({ where: { cedula_paciente } });
        if (!tieneAntecedentes) return res.status(403).send({ message: "BLOQUEO: Paciente sin Antecedentes." });

        // --- LÓGICA DE CARPETA (CORREGIDA) ---
        // Buscamos la última carpeta ACTIVA (no cerrada), sin importar la fecha
        const ultimaCarpeta = await Carpeta.findOne({
            where: {
                cedula_paciente: cedula_paciente,
                estatus: { 
                    [Op.notIn]: ['Alta', 'Fallecido', 'Traslado'] 
                }
            },
            order: [['createdAt', 'DESC']]
        });

        let carpeta = ultimaCarpeta;

        // Si no hay carpeta activa, creamos una nueva (esto no debería pasar si el flujo es correcto, 
        // pero se mantiene por seguridad)
        if (!ultimaCarpeta) {
            console.log("⚠️ No se encontró carpeta activa. Creando nueva...");
            carpeta = await Carpeta.create({
                cedula_paciente: cedula_paciente,
                fecha_creacion: new Date(),
                estatus: 'ABIERTA',
                id_usuario: id_usuario || null,
                atendido_por: atendido_por || null
            });
        } else {
            console.log(`✅ Usando carpeta activa ID: ${carpeta.id_carpeta}`);
        }

        // --- CREAR DIAGNÓSTICO ---
        const nuevoDiagnostico = await Diagnostico.create({
            cedula_paciente,
            descripcion,
            tipo,
            observaciones,
            id_carpeta: carpeta.id_carpeta 
        });

        // --- CREAR ÓRDENES MÉDICAS (Con ID de Medicamento) ---
        let ordenCreada = null;
        if (indicaciones_inmediatas || tratamientos_sugeridos || requerimiento_medicamentos || examenes_complementarios || conducta_seguir) {
            
            console.log(`-> Guardando Orden con ID Medicamento: ${id_medicamento}`);

            ordenCreada = await OrdenesMedicas.create({
                cedula_paciente, 
                // Aseguramos que sea número o null
                id_medicamento: (id_medicamento && id_medicamento !== 0) ? Number(id_medicamento) : null,
                indicaciones_inmediatas,
                tratamientos_sugeridos,
                requerimiento_medicamentos,
                examenes_complementarios,
                conducta_seguir,
                estatus: 'PENDIENTE',
                id_carpeta: carpeta.id_carpeta 
            });

            if (conducta_seguir && conducta_seguir.toLowerCase().includes('alta')) {
                await Carpeta.update({ estatus: 'Alta' }, { where: { id_carpeta: carpeta.id_carpeta } });
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
        res.status(500).send({ message: error.message });
    }
};

// ==========================================
// 2. Actualizar Diagnóstico y Órdenes (PUT)
// ==========================================
exports.updateDiagnostico = async (req, res) => {
    console.log("--- Recibiendo petición para ACTUALIZAR Diagnóstico ---");
    try {
        const { id } = req.params; 
        const { 
            descripcion, tipo, observaciones, 
            id_orden, 
            id_medicamento, 
            indicaciones_inmediatas, tratamientos_sugeridos, 
            requerimiento_medicamentos, examenes_complementarios, conducta_seguir 
        } = req.body;

        // 1. Actualizar Diagnóstico
        const diagnostico = await Diagnostico.findByPk(id);
        if (!diagnostico) return res.status(404).send({ success: false, message: "No encontrado." });

        diagnostico.descripcion = descripcion;
        diagnostico.tipo = tipo;
        diagnostico.observaciones = observaciones;
        await diagnostico.save();

        // 2. Actualizar Órdenes Médicas
        let ordenActualizada = null;
        if (id_orden) {
            const orden = await OrdenesMedicas.findByPk(id_orden);
            if (orden) {
                console.log(`-> Actualizando Orden ${id_orden} con ID Medicamento: ${id_medicamento}`);
                
                orden.id_medicamento = (id_medicamento && id_medicamento !== 0) ? Number(id_medicamento) : null;
                orden.indicaciones_inmediatas = indicaciones_inmediatas;
                orden.tratamientos_sugeridos = tratamientos_sugeridos;
                orden.requerimiento_medicamentos = requerimiento_medicamentos;
                orden.examenes_complementarios = examenes_complementarios;
                orden.conducta_seguir = conducta_seguir;
                
                await orden.save();
                ordenActualizada = orden;

                if (conducta_seguir && conducta_seguir.toLowerCase().includes('alta')) {
                    await Carpeta.update({ estatus: 'Alta' }, { where: { id_carpeta: orden.id_carpeta } });
                }
            }
        }

        res.status(200).send({ 
            success: true, 
            message: "Datos actualizados correctamente.", 
            data: { diagnostico, orden: ordenActualizada }
        });

    } catch (error) {
        console.error("Error updateDiagnostico:", error);
        res.status(500).send({ message: error.message });
    }
};

// ==========================================
// 3. Obtener Diagnóstico y Órdenes ACTIVAS (CORREGIDO)
// ==========================================
exports.getDiagnosticoHoy = async (req, res) => {
    try {
        const { cedula } = req.params;

        // --- CORRECCIÓN: BUSCAR POR ESTATUS, NO POR FECHA ---
        const carpeta = await Carpeta.findOne({
            where: { 
                cedula_paciente: cedula, 
                estatus: { [Op.notIn]: ['Alta', 'Fallecido', 'Traslado'] } // Carpeta activa
            },
            order: [['createdAt', 'DESC']]
        });

        if (!carpeta) {
            // Si no hay carpeta activa, devolvemos null para que el frontend sepa que está vacío
            return res.status(200).send({ success: true, data: { diagnostico: null, orden: null } });
        }

        const diagnostico = await Diagnostico.findOne({ where: { id_carpeta: carpeta.id_carpeta } });
        const orden = await OrdenesMedicas.findOne({ where: { id_carpeta: carpeta.id_carpeta } });

        res.status(200).send({
            success: true,
            data: { diagnostico, orden }
        });

    } catch (error) {
        console.error("Error getDiagnosticoHoy:", error);
        res.status(500).send({ message: "Error al obtener diagnóstico." });
    }
};

// ==========================================
// 4. Historial (Opcional)
// ==========================================
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