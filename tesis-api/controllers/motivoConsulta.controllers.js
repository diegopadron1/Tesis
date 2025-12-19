const db = require('../models');
const MotivoConsulta = db.MotivoConsulta;
const Carpeta = db.Carpeta; 
const { Op } = require("sequelize"); 

// 1. CREAR MOTIVO (POST) - CON LÓGICA MULTI-VISITA
exports.createMotivoConsulta = async (req, res) => {
    console.log("Intentando crear Motivo de Consulta...");
    
    // Validar la entrada
    const { cedula_paciente, motivo_consulta } = req.body;
    const { id_usuario, atendido_por } = req.body; 

    if (!cedula_paciente || !motivo_consulta) {
        return res.status(400).send({
            success: false, 
            message: 'Debe proporcionar la cédula del paciente y el motivo de la consulta.'
        });
    }

    try {
        const inicioDia = new Date();
        inicioDia.setHours(0, 0, 0, 0);
        const finDia = new Date();
        finDia.setHours(23, 59, 59, 999);

        // --- LÓGICA DE CARPETA INTELIGENTE ---
        
        // A. Buscar la ÚLTIMA carpeta de hoy (la más reciente)
        const ultimaCarpeta = await Carpeta.findOne({
            where: {
                cedula_paciente: cedula_paciente,
                createdAt: { [Op.gte]: inicioDia, [Op.lte]: finDia }
            },
            order: [['createdAt', 'DESC']] // <--- IMPORTANTE: Traer la última creada
        });

        let carpeta;

        // B. Decidir: ¿Crear Nueva o Usar Existente?
        // Condición: Si NO existe carpeta hoy, O SI la última ya fue dada de 'Alta'
        if (!ultimaCarpeta || ultimaCarpeta.estatus === 'Alta') {
            console.log(`📂 Creando NUEVA carpeta para ${cedula_paciente} (Nueva visita o reingreso)...`);
            
            carpeta = await Carpeta.create({
                cedula_paciente: cedula_paciente,
                fecha_creacion: new Date(),
                estatus: 'ABIERTA', // Siempre nace abierta
                id_usuario: id_usuario || null,
                atendido_por: atendido_por || null
            });
        } else {
            console.log(`📂 Usando carpeta existente ID ${ultimaCarpeta.id_carpeta} (El paciente sigue en atención)...`);
            carpeta = ultimaCarpeta;
        }

        // --- CREAR EL REGISTRO VINCULADO ---
        const nuevoMotivo = await MotivoConsulta.create({
            cedula_paciente: cedula_paciente,
            motivo_consulta: motivo_consulta,
            id_carpeta: carpeta.id_carpeta 
        });

        // Respuesta exitosa
        res.status(201).send({
            success: true, 
            message: 'Motivo de consulta registrado exitosamente.',
            data: nuevoMotivo, 
            id_carpeta: carpeta.id_carpeta 
        });

    } catch (error) {
        console.error('Error al crear motivo de consulta:', error);
        res.status(500).send({
            success: false,
            message: error.message || 'Ocurrió un error interno.'
        });
    }
};

// 2. ACTUALIZAR MOTIVO (PUT)
exports.updateMotivo = async (req, res) => {
    try {
        const { id } = req.params; 
        const { motivo_consulta } = req.body; 

        const motivo = await MotivoConsulta.findByPk(id);

        if (!motivo) {
            return res.status(404).send({ 
                success: false,
                message: "Motivo no encontrado." 
            });
        }

        motivo.motivo_consulta = motivo_consulta;
        await motivo.save();

        res.status(200).send({ 
            success: true,
            message: "Motivo actualizado correctamente.",
            data: motivo
        });

    } catch (error) {
        console.error("Error updateMotivo:", error);
        res.status(500).send({ 
            success: false,
            message: "Error al actualizar: " + error.message 
        });
    }
};

// Obtener Motivo y Triaje de HOY
exports.getByCedulaHoy = async (req, res) => {
    try {
        const { cedula } = req.params;
        console.log(`🔍 Buscando datos de HOY para cédula: ${cedula}`);

        const inicioDia = new Date(); inicioDia.setHours(0, 0, 0, 0);
        const finDia = new Date(); finDia.setHours(23, 59, 59, 999);

        // 1. Buscar la ÚLTIMA carpeta de hoy
        const carpeta = await Carpeta.findOne({
            where: {
                cedula_paciente: cedula,
                createdAt: { [Op.gte]: inicioDia, [Op.lte]: finDia }
            },
            order: [['createdAt', 'DESC']] 
        });

        // Caso A: No existe carpeta hoy
        if (!carpeta) {
            console.log("❌ No se encontró carpeta para hoy.");
            return res.status(200).send({ success: true, data: { motivo: null, triaje: null } });
        }

        console.log(`✅ Carpeta encontrada ID: ${carpeta.id_carpeta} (Estatus: ${carpeta.estatus})`);
        console.log(`ℹ️ Estatus en Base de Datos: "${carpeta.estatus}"`);

        // --- CORRECCIÓN AQUÍ ---
        // Caso B: Existe carpeta, PERO está de 'Alta'.
        // Debemos devolver NULL para que el frontend permita crear un ingreso nuevo.
        if (carpeta.estatus === 'Alta') {
            console.log("⚠️ La carpeta encontrada está CERRADA (Alta). Se retornan datos vacíos para nuevo ingreso.");
            return res.status(200).send({ 
                success: true, 
                data: { motivo: null, triaje: null } // <--- Fingimos que no hay datos
            });
        }
        // -----------------------

        // 2. Buscar datos (Solo si la carpeta está ABIERTA)
        const MotivoConsulta = db.MotivoConsulta;
        const Triaje = db.Triaje; 

        const motivo = await MotivoConsulta.findOne({ where: { id_carpeta: carpeta.id_carpeta } });
        const triaje = await Triaje.findOne({ where: { id_carpeta: carpeta.id_carpeta } });

        res.status(200).send({
            success: true,
            data: {
                motivo: motivo,
                triaje: triaje
            }
        });

    } catch (error) {
        console.error("🔥 Error CRÍTICO en getByCedulaHoy:", error);
        res.status(500).send({ message: "Error al obtener datos." });
    }
};