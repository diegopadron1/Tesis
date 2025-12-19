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
        const inicioDia = new Date(); inicioDia.setHours(0, 0, 0, 0);
        const finDia = new Date(); finDia.setHours(23, 59, 59, 999);

        // 1. Buscar la ÚLTIMA carpeta de hoy
        const ultimaCarpeta = await Carpeta.findOne({
            where: {
                cedula_paciente: cedula_paciente,
                createdAt: { [Op.gte]: inicioDia, [Op.lte]: finDia }
            },
            order: [['createdAt', 'DESC']] // <--- Importante: La más reciente
        });

        let carpeta;

        // 2. Si no existe O si la última ya está de Alta -> Crear Nueva
        if (!ultimaCarpeta || ultimaCarpeta.estatus === 'Alta') {
            console.log(`📂 Creando carpeta automática (Examen Físico) para ${cedula_paciente}...`);
            carpeta = await Carpeta.create({
                cedula_paciente,
                fecha_creacion: new Date(),
                estatus: 'ABIERTA',
                id_usuario: id_usuario || null,
                atendido_por: atendido_por || null
            });
        } else {
            // Usar la existente
            carpeta = ultimaCarpeta;
        }

        const nuevoFisico = await ExamenFisico.create({
            cedula_paciente,
            area,
            hallazgos,
            id_carpeta: carpeta.id_carpeta // Vinculación
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
        const inicioDia = new Date(); inicioDia.setHours(0, 0, 0, 0);
        const finDia = new Date(); finDia.setHours(23, 59, 59, 999);

        // 1. Buscar la ÚLTIMA carpeta de hoy
        const ultimaCarpeta = await Carpeta.findOne({
            where: {
                cedula_paciente: cedula_paciente,
                createdAt: { [Op.gte]: inicioDia, [Op.lte]: finDia }
            },
            order: [['createdAt', 'DESC']] // <--- Importante
        });

        let carpeta;

        // 2. Si no existe O si la última ya está de Alta -> Crear Nueva
        if (!ultimaCarpeta || ultimaCarpeta.estatus === 'Alta') {
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
            id_carpeta: carpeta.id_carpeta // Vinculación
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

// --- OBTENER EXÁMENES DE HOY ---
exports.getExamenesHoy = async (req, res) => {
    try {
        const { cedula } = req.params;
        const inicioDia = new Date(); inicioDia.setHours(0, 0, 0, 0);
        const finDia = new Date(); finDia.setHours(23, 59, 59, 999);

        // 1. Buscar la ÚLTIMA carpeta de Hoy
        const carpeta = await Carpeta.findOne({
            where: {
                cedula_paciente: cedula,
                createdAt: { [Op.gte]: inicioDia, [Op.lte]: finDia }
            },
            order: [['createdAt', 'DESC']] // <--- Importante
        });

        // A. Si no hay carpeta hoy
        if (!carpeta) {
            return res.status(200).send({ success: true, data: { fisico: null, funcional: null } });
        }

        // B. Si la carpeta está CERRADA (Alta) -> Devolvemos vacio para permitir nuevo ingreso
        if (carpeta.estatus === 'Alta') {
            return res.status(200).send({ success: true, data: { fisico: null, funcional: null } });
        }

        // 2. Buscar Examen Físico y Funcional de esa carpeta ABIERTA
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