const db = require('../models');
const AntecedentesPersonales = db.AntecedentesPersonales;
const AntecedentesFamiliares = db.AntecedentesFamiliares;
const HabitosPsicobiologicos = db.HabitosPsicobiologicos;
const Carpeta = db.Carpeta; // Importante: Traemos el modelo Carpeta
const { Op } = require("sequelize"); // Importante: Para rangos de fecha

// 1. Crear Antecedente Personal
exports.createPersonal = async (req, res) => {
    try {
        const { cedula_paciente, tipo, detalle } = req.body;
        // Opcional: datos del médico
        const { id_usuario, atendido_por } = req.body;

        if (!cedula_paciente || !tipo || !detalle) {
            return res.status(400).send({ message: "Faltan datos obligatorios." });
        }

        // --- LÓGICA DE CARPETA AUTOMÁTICA ---
        const inicioDia = new Date(); inicioDia.setHours(0, 0, 0, 0);
        const finDia = new Date(); finDia.setHours(23, 59, 59, 999);

        let carpeta = await Carpeta.findOne({
            where: {
                cedula_paciente: cedula_paciente,
                createdAt: { [Op.gte]: inicioDia, [Op.lte]: finDia }
            }
        });

        if (!carpeta) {
            console.log(`📂 Creando carpeta automática (Ant. Personal) para ${cedula_paciente}...`);
            carpeta = await Carpeta.create({
                cedula_paciente: cedula_paciente,
                fecha_creacion: new Date(),
                estatus: 'ABIERTA',
                id_usuario: id_usuario || null,
                atendido_por: atendido_por || null
            });
        }

        // --- GUARDAR ---
        const nuevo = await AntecedentesPersonales.create({ 
            cedula_paciente, 
            tipo, 
            detalle,
            id_carpeta: carpeta.id_carpeta // Vinculación obligatoria
        });

        res.status(201).send({ 
            message: "Antecedente Personal registrado.", 
            data: nuevo,
            id_carpeta: carpeta.id_carpeta
        });

    } catch (error) {
        console.error("Error antecedente personal:", error);
        res.status(500).send({ message: error.message || "Error al registrar antecedente personal." });
    }
};

// 2. Crear Antecedente Familiar
exports.createFamiliar = async (req, res) => {
    try {
        const { cedula_paciente, tipo_familiar, vivo_muerto, edad, patologias } = req.body;
        const { id_usuario, atendido_por } = req.body;

        if (!cedula_paciente || !tipo_familiar || !vivo_muerto) {
            return res.status(400).send({ message: "Faltan datos obligatorios." });
        }

        // --- LÓGICA DE CARPETA AUTOMÁTICA ---
        const inicioDia = new Date(); inicioDia.setHours(0, 0, 0, 0);
        const finDia = new Date(); finDia.setHours(23, 59, 59, 999);

        let carpeta = await Carpeta.findOne({
            where: {
                cedula_paciente: cedula_paciente,
                createdAt: { [Op.gte]: inicioDia, [Op.lte]: finDia }
            }
        });

        if (!carpeta) {
            console.log(`📂 Creando carpeta automática (Ant. Familiar) para ${cedula_paciente}...`);
            carpeta = await Carpeta.create({
                cedula_paciente: cedula_paciente,
                fecha_creacion: new Date(),
                estatus: 'ABIERTA',
                id_usuario: id_usuario || null,
                atendido_por: atendido_por || null
            });
        }

        // --- GUARDAR ---
        const nuevo = await AntecedentesFamiliares.create({ 
            cedula_paciente, 
            tipo_familiar, 
            vivo_muerto, 
            edad, 
            patologias,
            id_carpeta: carpeta.id_carpeta // Vinculación obligatoria
        });

        res.status(201).send({ 
            message: "Antecedente Familiar registrado.", 
            data: nuevo,
            id_carpeta: carpeta.id_carpeta
        });

    } catch (error) {
        console.error("Error antecedente familiar:", error);
        res.status(500).send({ message: error.message || "Error al registrar antecedente familiar." });
    }
};

// 3. Crear Hábitos Psicobiológicos
exports.createHabitos = async (req, res) => {
    try {
        const { cedula_paciente, cafe, tabaco, alcohol, drogas_ilicitas, ocupacion, sueño, vivienda } = req.body;
        const { id_usuario, atendido_por } = req.body;
        
        if (!cedula_paciente) {
            return res.status(400).send({ message: "La cédula del paciente es obligatoria." });
        }

        // --- LÓGICA DE CARPETA AUTOMÁTICA ---
        const inicioDia = new Date(); inicioDia.setHours(0, 0, 0, 0);
        const finDia = new Date(); finDia.setHours(23, 59, 59, 999);

        let carpeta = await Carpeta.findOne({
            where: {
                cedula_paciente: cedula_paciente,
                createdAt: { [Op.gte]: inicioDia, [Op.lte]: finDia }
            }
        });

        if (!carpeta) {
            console.log(`📂 Creando carpeta automática (Hábitos) para ${cedula_paciente}...`);
            carpeta = await Carpeta.create({
                cedula_paciente: cedula_paciente,
                fecha_creacion: new Date(),
                estatus: 'ABIERTA',
                id_usuario: id_usuario || null,
                atendido_por: atendido_por || null
            });
        }

        // --- GUARDAR ---
        const nuevo = await HabitosPsicobiologicos.create({
            cedula_paciente, cafe, tabaco, alcohol, drogas_ilicitas, ocupacion, sueño, vivienda,
            id_carpeta: carpeta.id_carpeta // Vinculación obligatoria
        });

        res.status(201).send({ 
            message: "Hábitos registrados.", 
            data: nuevo,
            id_carpeta: carpeta.id_carpeta
        });

    } catch (error) {
        console.error("Error hábitos:", error);
        res.status(500).send({ message: error.message || "Error al registrar hábitos." });
    }
};