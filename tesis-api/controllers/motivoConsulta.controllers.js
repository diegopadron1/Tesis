const db = require('../models');
const MotivoConsulta = db.MotivoConsulta;
const Carpeta = db.Carpeta; 
const { Op } = require("sequelize"); 

// 1. CREAR MOTIVO (POST)
exports.createMotivoConsulta = async (req, res) => {
    console.log("Intentando crear Motivo de Consulta...");
    
    // Validar la entrada
    const { cedula_paciente, motivo_consulta } = req.body;
    const { id_usuario, atendido_por } = req.body; 

    if (!cedula_paciente || !motivo_consulta) {
        return res.status(400).send({
            success: false, // Agregado para consistencia
            message: 'Debe proporcionar la cédula del paciente y el motivo de la consulta.'
        });
    }

    try {
        // --- LÓGICA DE CARPETA AUTOMÁTICA ---
        const inicioDia = new Date();
        inicioDia.setHours(0, 0, 0, 0);
        const finDia = new Date();
        finDia.setHours(23, 59, 59, 999);

        // A. Buscar carpeta existente de hoy
        let carpeta = await Carpeta.findOne({
            where: {
                cedula_paciente: cedula_paciente,
                createdAt: { [Op.gte]: inicioDia, [Op.lte]: finDia }
            }
        });

        // B. Si no existe, crearla
        if (!carpeta) {
            console.log(`📂 Creando carpeta automática para ${cedula_paciente}...`);
            carpeta = await Carpeta.create({
                cedula_paciente: cedula_paciente,
                fecha_creacion: new Date(),
                estatus: 'ABIERTA',
                id_usuario: id_usuario || null,
                atendido_por: atendido_por || null
            });
        }

        // --- CREAR EL REGISTRO VINCULADO ---
        const nuevoMotivo = await MotivoConsulta.create({
            cedula_paciente: cedula_paciente,
            motivo_consulta: motivo_consulta,
            id_carpeta: carpeta.id_carpeta 
        });

        // Respuesta exitosa
        res.status(201).send({
            success: true, // Importante para el frontend
            message: 'Motivo de consulta registrado exitosamente.',
            data: nuevoMotivo, // Flutter busca esto para obtener el ID
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

// 2. ACTUALIZAR MOTIVO (PUT) <--- ESTA ES LA QUE FALTABA
exports.updateMotivo = async (req, res) => {
    try {
        const { id } = req.params; // El ID que viene en la URL (ej: /api/motivo-consulta/32)
        const { motivo_consulta } = req.body; // El nuevo texto editado

        // Buscamos el registro usando el modelo correcto 'MotivoConsulta'
        const motivo = await MotivoConsulta.findByPk(id);

        if (!motivo) {
            return res.status(404).send({ 
                success: false,
                message: "Motivo no encontrado." 
            });
        }

        // Actualizamos el campo
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