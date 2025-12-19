const db = require('../models');
const AntecedentesPersonales = db.AntecedentesPersonales;
const AntecedentesFamiliares = db.AntecedentesFamiliares;
const HabitosPsicobiologicos = db.HabitosPsicobiologicos;
const Carpeta = db.Carpeta; 
const { Op } = require("sequelize"); 

// 1. Crear Antecedente Personal (CON LÓGICA DE CARPETA INTELIGENTE)
exports.createPersonal = async (req, res) => {
    try {
        const { cedula_paciente, tipo, detalle } = req.body;
        const { id_usuario, atendido_por } = req.body;

        if (!cedula_paciente || !tipo || !detalle) {
            return res.status(400).send({ message: "Faltan datos obligatorios." });
        }

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
            console.log(`📂 Creando carpeta automática (Ant. Personal) para ${cedula_paciente}...`);
            carpeta = await Carpeta.create({
                cedula_paciente: cedula_paciente,
                fecha_creacion: new Date(),
                estatus: 'ABIERTA',
                id_usuario: id_usuario || null,
                atendido_por: atendido_por || null
            });
        } else {
            // Usar la existente
            carpeta = ultimaCarpeta;
        }

        const nuevo = await AntecedentesPersonales.create({ 
            cedula_paciente, 
            tipo, 
            detalle,
            id_carpeta: carpeta.id_carpeta 
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

// 2. Crear Antecedente Familiar (CON LÓGICA DE CARPETA INTELIGENTE)
exports.createFamiliar = async (req, res) => {
    try {
        const { cedula_paciente, tipo_familiar, vivo_muerto, edad, patologias } = req.body;
        const { id_usuario, atendido_por } = req.body;

        if (!cedula_paciente || !tipo_familiar || !vivo_muerto) {
            return res.status(400).send({ message: "Faltan datos obligatorios." });
        }

        const inicioDia = new Date(); inicioDia.setHours(0, 0, 0, 0);
        const finDia = new Date(); finDia.setHours(23, 59, 59, 999);

        // 1. Buscar la ÚLTIMA carpeta de hoy
        const ultimaCarpeta = await Carpeta.findOne({
            where: {
                cedula_paciente: cedula_paciente,
                createdAt: { [Op.gte]: inicioDia, [Op.lte]: finDia }
            },
            order: [['createdAt', 'DESC']]
        });

        let carpeta;

        // 2. Si no existe O si la última ya está de Alta -> Crear Nueva
        if (!ultimaCarpeta || ultimaCarpeta.estatus === 'Alta') {
            console.log(`📂 Creando carpeta automática (Ant. Familiar) para ${cedula_paciente}...`);
            carpeta = await Carpeta.create({
                cedula_paciente: cedula_paciente,
                fecha_creacion: new Date(),
                estatus: 'ABIERTA',
                id_usuario: id_usuario || null,
                atendido_por: atendido_por || null
            });
        } else {
            carpeta = ultimaCarpeta;
        }

        const nuevo = await AntecedentesFamiliares.create({ 
            cedula_paciente, 
            tipo_familiar, 
            vivo_muerto, 
            edad, 
            patologias,
            id_carpeta: carpeta.id_carpeta 
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

// 3. Crear Hábitos Psicobiológicos (CON LÓGICA DE CARPETA INTELIGENTE)
exports.createHabitos = async (req, res) => {
    try {
        const { cedula_paciente, cafe, tabaco, alcohol, drogas_ilicitas, ocupacion, sueño, vivienda } = req.body;
        const { id_usuario, atendido_por } = req.body;
        
        if (!cedula_paciente) {
            return res.status(400).send({ message: "La cédula del paciente es obligatoria." });
        }

        const inicioDia = new Date(); inicioDia.setHours(0, 0, 0, 0);
        const finDia = new Date(); finDia.setHours(23, 59, 59, 999);

        // 1. Buscar la ÚLTIMA carpeta de hoy
        const ultimaCarpeta = await Carpeta.findOne({
            where: {
                cedula_paciente: cedula_paciente,
                createdAt: { [Op.gte]: inicioDia, [Op.lte]: finDia }
            },
            order: [['createdAt', 'DESC']]
        });

        let carpeta;

        // 2. Si no existe O si la última ya está de Alta -> Crear Nueva
        if (!ultimaCarpeta || ultimaCarpeta.estatus === 'Alta') {
            console.log(`📂 Creando carpeta automática (Hábitos) para ${cedula_paciente}...`);
            carpeta = await Carpeta.create({
                cedula_paciente: cedula_paciente,
                fecha_creacion: new Date(),
                estatus: 'ABIERTA',
                id_usuario: id_usuario || null,
                atendido_por: atendido_por || null
            });
        } else {
            carpeta = ultimaCarpeta;
        }

        const nuevo = await HabitosPsicobiologicos.create({
            cedula_paciente, cafe, tabaco, alcohol, drogas_ilicitas, ocupacion, sueño, vivienda,
            id_carpeta: carpeta.id_carpeta 
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

// ==========================================
// ACTUALIZACIONES (PUT) - SE MANTIENEN IGUAL
// ==========================================

// 4. Actualizar Antecedente Personal
exports.updatePersonal = async (req, res) => {
    try {
        const { id } = req.params;
        const { tipo, detalle } = req.body;

        const registro = await AntecedentesPersonales.findByPk(id);
        if (!registro) return res.status(404).send({ success: false, message: "Registro no encontrado." });

        registro.tipo = tipo;
        registro.detalle = detalle;
        await registro.save();

        res.status(200).send({ success: true, message: "Antecedente Personal actualizado.", data: registro });
    } catch (error) {
        res.status(500).send({ message: "Error interno: " + error.message });
    }
};

// 5. Actualizar Antecedente Familiar
exports.updateFamiliar = async (req, res) => {
    try {
        const { id } = req.params;
        const { tipo_familiar, vivo_muerto, edad, patologias } = req.body;

        const registro = await AntecedentesFamiliares.findByPk(id);
        if (!registro) return res.status(404).send({ success: false, message: "Registro no encontrado." });

        registro.tipo_familiar = tipo_familiar;
        registro.vivo_muerto = vivo_muerto;
        registro.edad = edad;
        registro.patologias = patologias;
        await registro.save();

        res.status(200).send({ success: true, message: "Antecedente Familiar actualizado.", data: registro });
    } catch (error) {
        res.status(500).send({ message: "Error interno: " + error.message });
    }
};

// 6. Actualizar Hábitos
exports.updateHabitos = async (req, res) => {
    try {
        const { id } = req.params;
        const { cafe, tabaco, alcohol, drogas_ilicitas, ocupacion, sueño, vivienda } = req.body;

        const registro = await HabitosPsicobiologicos.findByPk(id);
        if (!registro) return res.status(404).send({ success: false, message: "Registro no encontrado." });

        // Actualizar campos
        registro.cafe = cafe;
        registro.tabaco = tabaco;
        registro.alcohol = alcohol;
        registro.drogas_ilicitas = drogas_ilicitas;
        registro.ocupacion = ocupacion;
        registro.sueño = sueño; 
        registro.vivienda = vivienda;
        
        await registro.save();

        res.status(200).send({ success: true, message: "Hábitos actualizados.", data: registro });
    } catch (error) {
        res.status(500).send({ message: "Error interno: " + error.message });
    }
};

// ==========================================
// CONSULTA (GET) - CON LÓGICA DE ALTA
// ==========================================
exports.getAntecedentesHoy = async (req, res) => {
    try {
        const { cedula } = req.params;
        const inicioDia = new Date(); inicioDia.setHours(0, 0, 0, 0);
        const finDia = new Date(); finDia.setHours(23, 59, 59, 999);

        // 1. Buscar la ÚLTIMA carpeta de hoy
        const carpeta = await Carpeta.findOne({
            where: { cedula_paciente: cedula, createdAt: { [Op.gte]: inicioDia, [Op.lte]: finDia } },
            order: [['createdAt', 'DESC']] // <--- Importante
        });

        // A. Si no hay carpeta
        if (!carpeta) {
            return res.status(200).send({ success: true, data: { personal: null, familiar: null, habitos: null } });
        }

        // B. Si la carpeta está CERRADA (Alta) -> Retornar vacío para nuevo ingreso
        if (carpeta.estatus === 'Alta') {
            return res.status(200).send({ success: true, data: { personal: null, familiar: null, habitos: null } });
        }

        // 2. Buscar los 3 tipos vinculados a esa carpeta ABIERTA
        const personal = await AntecedentesPersonales.findOne({ where: { id_carpeta: carpeta.id_carpeta } });
        const familiar = await AntecedentesFamiliares.findOne({ where: { id_carpeta: carpeta.id_carpeta } });
        const habitos = await HabitosPsicobiologicos.findOne({ where: { id_carpeta: carpeta.id_carpeta } });

        res.status(200).send({
            success: true,
            data: { personal, familiar, habitos }
        });

    } catch (error) {
        console.error(error);
        res.status(500).send({ message: "Error al obtener antecedentes." });
    }
};