const db = require('../models');
const ExamenFisico = db.ExamenFisico;
const ExamenFuncional = db.ExamenFuncional;
const Carpeta = db.Carpeta; 
const { Op } = require("sequelize"); 

// --- CREAR EXAMEN FÍSICO (Ya existente) ---
exports.createExamenFisico = async (req, res) => {
    console.log("Intentando crear Examen Físico...");
    const { cedula_paciente, area, hallazgos } = req.body;
    const { id_usuario, atendido_por } = req.body; 

    if (!cedula_paciente || !area || !hallazgos) {
        return res.status(400).send({ message: 'Faltan datos: Cédula, Área o Hallazgos.' });
    }

    try {
        const inicioDia = new Date(); inicioDia.setHours(0, 0, 0, 0);
        const finDia = new Date(); finDia.setHours(23, 59, 59, 999);

        let carpeta = await Carpeta.findOne({
            where: {
                cedula_paciente: cedula_paciente,
                createdAt: { [Op.gte]: inicioDia, [Op.lte]: finDia }
            }
        });

        if (!carpeta) {
            console.log(`📂 Creando carpeta automática (Examen Físico) para ${cedula_paciente}...`);
            carpeta = await Carpeta.create({
                cedula_paciente: cedula_paciente,
                fecha_creacion: new Date(),
                estatus: 'ABIERTA',
                id_usuario: id_usuario || null,
                atendido_por: atendido_por || null
            });
        }

        const nuevoFisico = await ExamenFisico.create({
            cedula_paciente,
            area,
            hallazgos,
            id_carpeta: carpeta.id_carpeta 
        });

        res.status(201).send({ 
            success: true, // Agregado para consistencia
            message: 'Examen Físico registrado exitosamente.', 
            data: nuevoFisico, // Importante para capturar ID en Flutter
            id_carpeta: carpeta.id_carpeta 
        });

    } catch (error) {
        console.error("Error creando Examen Físico:", error);
        res.status(500).send({ message: error.message || 'Error al registrar examen físico.' });
    }
};

// --- CREAR EXAMEN FUNCIONAL (Ya existente) ---
exports.createExamenFuncional = async (req, res) => {
    console.log("Intentando crear Examen Funcional...");
    const { cedula_paciente, sistema, hallazgos } = req.body;
    const { id_usuario, atendido_por } = req.body;

    if (!cedula_paciente || !sistema || !hallazgos) {
        return res.status(400).send({ message: 'Faltan datos: Cédula, Sistema o Hallazgos.' });
    }

    try {
        const inicioDia = new Date(); inicioDia.setHours(0, 0, 0, 0);
        const finDia = new Date(); finDia.setHours(23, 59, 59, 999);

        let carpeta = await Carpeta.findOne({
            where: {
                cedula_paciente: cedula_paciente,
                createdAt: { [Op.gte]: inicioDia, [Op.lte]: finDia }
            }
        });

        if (!carpeta) {
            console.log(`📂 Creando carpeta automática (Examen Funcional) para ${cedula_paciente}...`);
            carpeta = await Carpeta.create({
                cedula_paciente: cedula_paciente,
                fecha_creacion: new Date(),
                estatus: 'ABIERTA',
                id_usuario: id_usuario || null,
                atendido_por: atendido_por || null
            });
        }

        const nuevoFuncional = await ExamenFuncional.create({
            cedula_paciente,
            sistema,
            hallazgos,
            id_carpeta: carpeta.id_carpeta 
        });

        res.status(201).send({ 
            success: true, // Agregado para consistencia
            message: 'Examen Funcional registrado exitosamente.', 
            data: nuevoFuncional, // Importante para capturar ID en Flutter
            id_carpeta: carpeta.id_carpeta 
        });

    } catch (error) {
        console.error("Error creando Examen Funcional:", error);
        res.status(500).send({ message: error.message || 'Error al registrar examen funcional.' });
    }
};

// ==========================================================
// NUEVAS FUNCIONES DE ACTUALIZACIÓN (PUT)
// ==========================================================

// --- ACTUALIZAR EXAMEN FÍSICO ---
exports.updateExamenFisico = async (req, res) => {
    try {
        const { id } = req.params;
        const { area, hallazgos } = req.body;

        // Buscar por Primary Key (id_examen_fisico o id)
        const examen = await ExamenFisico.findByPk(id);

        if (!examen) {
            return res.status(404).send({ 
                success: false, 
                message: "Examen Físico no encontrado." 
            });
        }

        // Actualizar datos
        examen.area = area;
        examen.hallazgos = hallazgos;
        await examen.save();

        res.status(200).send({ 
            success: true,
            message: "Examen Físico actualizado correctamente.",
            data: examen 
        });

    } catch (error) {
        console.error("Error actualizando Examen Físico:", error);
        res.status(500).send({ message: "Error interno: " + error.message });
    }
};

// --- ACTUALIZAR EXAMEN FUNCIONAL ---
exports.updateExamenFuncional = async (req, res) => {
    try {
        const { id } = req.params;
        const { sistema, hallazgos } = req.body;

        const examen = await ExamenFuncional.findByPk(id);

        if (!examen) {
            return res.status(404).send({ 
                success: false, 
                message: "Examen Funcional no encontrado." 
            });
        }

        // Actualizar datos
        examen.sistema = sistema;
        examen.hallazgos = hallazgos;
        await examen.save();

        res.status(200).send({ 
            success: true,
            message: "Examen Funcional actualizado correctamente.",
            data: examen 
        });

    } catch (error) {
        console.error("Error actualizando Examen Funcional:", error);
        res.status(500).send({ message: "Error interno: " + error.message });
    }
};