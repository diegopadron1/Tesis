const db = require('../models');
const ExamenFisico = db.ExamenFisico;
const ExamenFuncional = db.ExamenFuncional;
const Carpeta = db.Carpeta; 
const { Op } = require("sequelize"); 

// --- CREAR EXAMEN FÍSICO ---
exports.createExamenFisico = async (req, res) => {
    console.log("Intentando crear Examen Físico...");
    const { cedula_paciente, area, hallazgos } = req.body;
    const { id_usuario, atendido_por } = req.body; 

    if (!cedula_paciente || !area || !hallazgos) {
        return res.status(400).send({ message: 'Faltan datos.' });
    }

    try {
        // --- CORRECCIÓN: BUSCAR POR ESTATUS, NO POR FECHA ---
        const ultimaCarpeta = await Carpeta.findOne({
            where: {
                cedula_paciente: cedula_paciente,
                estatus: { 
                    [Op.notIn]: ['Alta', 'Fallecido', 'Traslado'] 
                }
            },
            order: [['createdAt', 'DESC']]
        });

        let carpeta;

        // Si no existe carpeta activa, crear nueva
        if (!ultimaCarpeta) {
            console.log(`📂 Creando carpeta automática (Examen Físico) para ${cedula_paciente}...`);
            carpeta = await Carpeta.create({
                cedula_paciente,
                fecha_creacion: new Date(),
                estatus: 'ABIERTA',
                id_usuario: id_usuario || null,
                atendido_por: atendido_por || null
            });
        } else {
            carpeta = ultimaCarpeta;
        }

        const nuevoFisico = await ExamenFisico.create({
            cedula_paciente,
            area,
            hallazgos,
            id_carpeta: carpeta.id_carpeta 
        });

        res.status(201).send({ 
            success: true,
            message: 'Examen Físico guardado.', 
            data: nuevoFisico
        });

    } catch (error) {
        console.error("Error Examen Físico:", error);
        res.status(500).send({ message: error.message });
    }
};

// --- CREAR EXAMEN FUNCIONAL ---
exports.createExamenFuncional = async (req, res) => {
    console.log("Intentando crear Examen Funcional...");
    const { cedula_paciente, sistema, hallazgos } = req.body;
    const { id_usuario, atendido_por } = req.body;

    if (!cedula_paciente || !sistema || !hallazgos) {
        return res.status(400).send({ message: 'Faltan datos.' });
    }

    try {
        // --- CORRECCIÓN: BUSCAR POR ESTATUS, NO POR FECHA ---
        const ultimaCarpeta = await Carpeta.findOne({
            where: {
                cedula_paciente: cedula_paciente,
                estatus: { 
                    [Op.notIn]: ['Alta', 'Fallecido', 'Traslado'] 
                }
            },
            order: [['createdAt', 'DESC']]
        });

        let carpeta;

        if (!ultimaCarpeta) {
            console.log(`📂 Creando carpeta automática (Examen Funcional) para ${cedula_paciente}...`);
            carpeta = await Carpeta.create({
                cedula_paciente,
                fecha_creacion: new Date(),
                estatus: 'ABIERTA',
                id_usuario: id_usuario || null,
                atendido_por: atendido_por || null
            });
        } else {
            carpeta = ultimaCarpeta;
        }

        const nuevoFuncional = await ExamenFuncional.create({
            cedula_paciente,
            sistema,
            hallazgos,
            id_carpeta: carpeta.id_carpeta 
        });

        res.status(201).send({ 
            success: true,
            message: 'Examen Funcional guardado.', 
            data: nuevoFuncional
        });

    } catch (error) {
        console.error("Error Examen Funcional:", error);
        res.status(500).send({ message: error.message });
    }
};

// --- ACTUALIZACIONES (PUT) ---
exports.updateExamenFisico = async (req, res) => {
    try {
        const { id } = req.params;
        await ExamenFisico.update(req.body, { where: { id_fisico: id } });
        res.status(200).send({ success: true, message: "Actualizado correctamente." });
    } catch (error) {
        res.status(500).send({ message: error.message });
    }
};

exports.updateExamenFuncional = async (req, res) => {
    try {
        const { id } = req.params;
        await ExamenFuncional.update(req.body, { where: { id_examen: id } });
        res.status(200).send({ success: true, message: "Actualizado correctamente." });
    } catch (error) {
        res.status(500).send({ message: error.message });
    }
};

// --- OBTENER EXÁMENES DE HOY (CORREGIDO) ---
exports.getExamenesHoy = async (req, res) => {
    try {
        const { cedula } = req.params;

        // --- CORRECCIÓN: BUSCAR POR ESTATUS, NO POR FECHA ---
        const carpeta = await Carpeta.findOne({
            where: { 
                cedula_paciente: cedula, 
                estatus: { 
                    [Op.notIn]: ['Alta', 'Fallecido', 'Traslado'] 
                }
            },
            order: [['createdAt', 'DESC']] 
        });

        if (!carpeta) {
            return res.status(200).send({ success: true, data: { fisico: null, funcional: null } });
        }

        const fisico = await ExamenFisico.findOne({ where: { id_carpeta: carpeta.id_carpeta } });
        const funcional = await ExamenFuncional.findOne({ where: { id_carpeta: carpeta.id_carpeta } });

        res.status(200).send({
            success: true,
            data: {
                fisico: fisico,
                funcional: funcional
            }
        });

    } catch (error) {
        console.error("Error getExamenesHoy:", error);
        res.status(500).send({ message: "Error al cargar exámenes." });
    }
};