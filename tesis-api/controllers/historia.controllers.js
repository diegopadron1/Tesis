const db = require('../models');
const { Op } = require("sequelize"); 

const Paciente = db.Paciente;
const Carpeta = db.Carpeta; 

// Modelos Hijos
const ContactoEmergencia = db.ContactoEmergencia;
const MotivoConsulta = db.MotivoConsulta;
const ExamenFisico = db.ExamenFisico;
const ExamenFuncional = db.ExamenFuncional;
const AntecedentesPersonales = db.AntecedentesPersonales;
const AntecedentesFamiliares = db.AntecedentesFamiliares;
const AntecedentesHabitos = db.HabitosPsicobiologicos;
const Diagnostico = db.Diagnostico;
const OrdenesMedicas = db.OrdenesMedicas;

// =========================================================================
// HELPER: BUSCAR O CREAR CARPETA DEL DÍA
// =========================================================================
const getCarpetaDelDia = async (cedulaPaciente, datosUsuario) => {
    const inicioDia = new Date();
    inicioDia.setHours(0, 0, 0, 0);

    const finDia = new Date();
    finDia.setHours(23, 59, 59, 999);

    let carpeta = await Carpeta.findOne({
        where: {
            cedula_paciente: cedulaPaciente,
            createdAt: { [Op.gte]: inicioDia, [Op.lte]: finDia }
        }
    });

    if (!carpeta) {
        const idMedico = datosUsuario?.id_usuario || null; 
        const nombreMedico = datosUsuario?.atendido_por || "Médico Tratante";

        carpeta = await Carpeta.create({
            cedula_paciente: cedulaPaciente,
            fecha_creacion: new Date(),
            estatus: 'ABIERTA',
            id_usuario: idMedico,
            atendido_por: nombreMedico
        });
        console.log(`📂 Nueva carpeta creada para ${cedulaPaciente} (ID: ${carpeta.id_carpeta})`);
    } else {
        console.log(`📂 Usando carpeta existente del día (ID: ${carpeta.id_carpeta})`);
    }

    return carpeta;
};

// =========================================================================
// 1. OBTENER HISTORIA COMPLETA (Usando Alias 'listado_carpetas')
// =========================================================================
exports.getHistoriaClinica = async (req, res) => {
    const { cedula } = req.params;
    console.log(`🔍 Consultando historia para Cédula: ${cedula}`);

    try {
        const paciente = await Paciente.findOne({
            where: { cedula: cedula },
            include: [
                { model: ContactoEmergencia }, 
                { 
                    model: Carpeta,
                    as: 'listado_carpetas', // <--- USAMOS EL ALIAS AQUÍ
                    include: [
                        { model: MotivoConsulta },
                        { model: ExamenFisico },
                        { model: ExamenFuncional },
                        { model: AntecedentesPersonales },
                        { model: AntecedentesFamiliares },
                        { model: AntecedentesHabitos },
                        { model: Diagnostico },
                        { model: OrdenesMedicas,
                          include: [{
                            model: db.Medicamento,
                            as: 'medicamento',
                            attributes: ['nombre', 'concentracion']
                         }]
                        }
                    ]
                }
            ],
            // Ordenar usando el alias
            order: [
                [{ model: Carpeta, as: 'listado_carpetas' }, 'createdAt', 'DESC']
            ]
        });

        if (!paciente) {
            console.log("❌ Paciente no encontrado");
            return res.status(404).send({ message: "Paciente no encontrado." });
        }

        const pacienteJSON = paciente.toJSON();
        // Sequelize pone los datos bajo el nombre del alias
        const carpetas = pacienteJSON.listado_carpetas || []; 

        console.log(`📂 Se encontraron ${carpetas.length} carpetas usando alias.`);

        // Inicializamos las listas
        pacienteJSON.MotivoConsultas = [];
        pacienteJSON.Diagnosticos = [];
        pacienteJSON.ExamenFisicos = [];
        pacienteJSON.ExamenFuncionals = [];
        pacienteJSON.AntecedentesPersonales = [];
        pacienteJSON.AntecedentesFamiliares = [];
        pacienteJSON.HabitosPsicobiologicos = [];
        pacienteJSON.OrdenesMedicas = [];

        // Helper para buscar propiedad insensible a mayúsculas/nombres raros
        const findProp = (obj, keys) => {
            for (const key of keys) {
                if (obj[key]) return obj[key];
            }
            return null;
        };

        carpetas.forEach((carpeta) => {
            const fechaCarpeta = carpeta.createdAt;
            const idCarpeta = carpeta.id_carpeta;

            const procesarItem = (item) => {
                if (item) {
                    item.fecha = fechaCarpeta;
                    item.id_carpeta = idCarpeta; 
                }
                return item;
            };

            const motivo = findProp(carpeta, ['MotivoConsultum', 'MotivoConsulta', 'motivoConsulta']);
            if (motivo) pacienteJSON.MotivoConsultas.push(procesarItem(motivo));

            const diagnostico = findProp(carpeta, ['Diagnostico', 'diagnostico']);
            if (diagnostico) pacienteJSON.Diagnosticos.push(procesarItem(diagnostico));

            const fisico = findProp(carpeta, ['ExamenFisico', 'examenFisico']);
            if (fisico) pacienteJSON.ExamenFisicos.push(procesarItem(fisico));

            const funcional = findProp(carpeta, ['ExamenFuncional', 'examenFuncional']);
            if (funcional) pacienteJSON.ExamenFuncionals.push(procesarItem(funcional));

            const antPers = findProp(carpeta, ['AntecedentesPersonale', 'AntecedentesPersonales']);
            if (antPers) pacienteJSON.AntecedentesPersonales.push(procesarItem(antPers));

            const antFam = findProp(carpeta, ['AntecedentesFamiliare', 'AntecedentesFamiliares']);
            if (antFam) pacienteJSON.AntecedentesFamiliares.push(procesarItem(antFam));

            const habitos = findProp(carpeta, ['HabitosPsicobiologico', 'HabitosPsicobiologicos']);
            if (habitos) pacienteJSON.HabitosPsicobiologicos.push(procesarItem(habitos));

            const ordenes = findProp(carpeta, ['OrdenesMedicas', 'OrdenesMedica']);
            if (ordenes && ordenes.length > 0) {
                const ordenesProcesadas = ordenes.map(o => {
                    o.id_carpeta = idCarpeta;
                    return o;
                });
                pacienteJSON.OrdenesMedicas.push(...ordenesProcesadas);
            }
        });

        console.log(`✅ Enviando respuesta: ${pacienteJSON.MotivoConsultas.length} motivos.`);
        res.status(200).send(pacienteJSON);

    } catch (error) {
        console.error("Error al obtener historia:", error);
        res.status(500).send({ message: "Error interno al cargar la historia clínica." });
    }
};

// =========================================================================
// 2. GUARDAR SECCIÓN (Lógica de Carpetas)
// =========================================================================
const upsertEnCarpeta = async (Modelo, data, idCarpeta) => {
    const existe = await Modelo.findOne({ where: { id_carpeta: idCarpeta } });
    if (existe) {
        return await existe.update(data);
    } else {
        return await Modelo.create({ ...data, id_carpeta: idCarpeta });
    }
};

exports.guardarSeccion = async (req, res) => {
    const { cedula } = req.params;
    const { seccion, datos } = req.body; 

    if (!cedula || !seccion || !datos) {
        return res.status(400).send({ message: "Faltan datos." });
    }

    try {
        let resultado;

        if (seccion === 'datos_personales') {
            await Paciente.update(datos, { where: { cedula: cedula } });
            return res.status(200).send({ message: "Datos personales actualizados.", success: true });
        }

        if (seccion === 'contacto_emergencia') {
            const existe = await ContactoEmergencia.findOne({ where: { cedula_paciente: cedula } });
            if (existe) await existe.update(datos);
            else await ContactoEmergencia.create({ ...datos, cedula_paciente: cedula });
            return res.status(200).send({ message: "Contacto de emergencia guardado.", success: true });
        }

        const carpeta = await getCarpetaDelDia(cedula, { 
            id_usuario: req.body.id_usuario,     
            atendido_por: req.body.atendido_por 
        });

        switch (seccion) {
            case 'motivo':
                resultado = await upsertEnCarpeta(MotivoConsulta, datos, carpeta.id_carpeta);
                break;
            case 'fisico':
                resultado = await upsertEnCarpeta(ExamenFisico, datos, carpeta.id_carpeta);
                break;
            case 'funcional':
                resultado = await upsertEnCarpeta(ExamenFuncional, datos, carpeta.id_carpeta);
                break;
            case 'ant_pers':
                resultado = await upsertEnCarpeta(AntecedentesPersonales, datos, carpeta.id_carpeta);
                break;
            case 'ant_fam':
                resultado = await upsertEnCarpeta(AntecedentesFamiliares, datos, carpeta.id_carpeta);
                break;
            case 'ant_hab':
                resultado = await upsertEnCarpeta(AntecedentesHabitos, datos, carpeta.id_carpeta);
                break;
            case 'diagnostico':
                resultado = await upsertEnCarpeta(Diagnostico, datos, carpeta.id_carpeta);
                break;
            case 'orden_medica': 
                resultado = await OrdenesMedicas.create({ ...datos, id_carpeta: carpeta.id_carpeta, estatus: 'PENDIENTE' });
                break;
            default:
                return res.status(400).send({ message: "Sección desconocida." });
        }

        res.status(200).send({ message: "Información guardada en la carpeta clínica.", success: true, data: resultado });

    } catch (error) {
        console.error(`Error guardando ${seccion}:`, error);
        res.status(500).send({ message: "Error al guardar la información." });
    }
};

// 3. EDITAR ORDEN MÉDICA
exports.editarOrdenMedica = async (req, res) => {
    const { id_orden } = req.params;
    const datosActualizados = req.body;

    try {
        const orden = await OrdenesMedicas.findByPk(id_orden);
        if (!orden) return res.status(404).send({ message: "Orden médica no encontrada." });
        if (orden.estatus !== 'PENDIENTE') return res.status(403).send({ message: `No se puede editar esta orden porque su estatus es ${orden.estatus}.` });

        await orden.update(datosActualizados);
        res.status(200).send({ message: "Orden médica actualizada correctamente.", success: true, orden });
    } catch (error) {
        console.error("Error editando orden:", error);
        res.status(500).send({ message: "Error interno al editar la orden." });
    }
};