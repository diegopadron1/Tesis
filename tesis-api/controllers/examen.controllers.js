const db = require('../models');
const ExamenFisico = db.ExamenFisico;
const ExamenFuncional = db.ExamenFuncional;
const Carpeta = db.Carpeta; // Importante: Traemos el modelo Carpeta
const { Op } = require("sequelize"); // Importante: Para rangos de fecha

// --- CREAR EXAMEN FÍSICO ---
exports.createExamenFisico = async (req, res) => {
    console.log("Intentando crear Examen Físico...");
    const { cedula_paciente, area, hallazgos } = req.body;
    
    // Opcional: capturar datos del médico si se envían
    const { id_usuario, atendido_por } = req.body; 

    if (!cedula_paciente || !area || !hallazgos) {
        return res.status(400).send({ message: 'Faltan datos: Cédula, Área o Hallazgos.' });
    }

    try {
        // 1. LÓGICA DE CARPETA AUTOMÁTICA
        const inicioDia = new Date(); inicioDia.setHours(0, 0, 0, 0);
        const finDia = new Date(); finDia.setHours(23, 59, 59, 999);

        // Buscar carpeta de hoy
        let carpeta = await Carpeta.findOne({
            where: {
                cedula_paciente: cedula_paciente,
                createdAt: { [Op.gte]: inicioDia, [Op.lte]: finDia }
            }
        });

        // Si no existe, crearla
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

        // 2. GUARDAR CON VINCULACIÓN
        const nuevoFisico = await ExamenFisico.create({
            cedula_paciente,
            area,
            hallazgos,
            id_carpeta: carpeta.id_carpeta // <--- OBLIGATORIO AHORA
        });

        res.status(201).send({ 
            message: 'Examen Físico registrado exitosamente.', 
            data: nuevoFisico,
            id_carpeta: carpeta.id_carpeta 
        });

    } catch (error) {
        console.error("Error creando Examen Físico:", error);
        res.status(500).send({ message: error.message || 'Error al registrar examen físico.' });
    }
};

// --- CREAR EXAMEN FUNCIONAL ---
exports.createExamenFuncional = async (req, res) => {
    console.log("Intentando crear Examen Funcional...");
    const { cedula_paciente, sistema, hallazgos } = req.body;
    const { id_usuario, atendido_por } = req.body;

    if (!cedula_paciente || !sistema || !hallazgos) {
        return res.status(400).send({ message: 'Faltan datos: Cédula, Sistema o Hallazgos.' });
    }

    try {
        // 1. LÓGICA DE CARPETA AUTOMÁTICA
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

        // 2. GUARDAR CON VINCULACIÓN
        const nuevoFuncional = await ExamenFuncional.create({
            cedula_paciente,
            sistema,
            hallazgos,
            id_carpeta: carpeta.id_carpeta // <--- OBLIGATORIO AHORA
        });

        res.status(201).send({ 
            message: 'Examen Funcional registrado exitosamente.', 
            data: nuevoFuncional, 
            id_carpeta: carpeta.id_carpeta 
        });

    } catch (error) {
        console.error("Error creando Examen Funcional:", error);
        res.status(500).send({ message: error.message || 'Error al registrar examen funcional.' });
    }
};