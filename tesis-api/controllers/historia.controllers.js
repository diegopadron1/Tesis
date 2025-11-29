const db = require('../models');
const Paciente = db.Paciente;
const MotivoConsulta = db.MotivoConsulta;
const ExamenFisico = db.ExamenFisico;
const ExamenFuncional = db.ExamenFuncional;
const AntecedentesPersonales = db.AntecedentesPersonales;
const AntecedentesFamiliares = db.AntecedentesFamiliares;

// CAMBIO AQUÍ: Usamos el nombre exacto que tienes en models/index.js
const AntecedentesHabitos = db.HabitosPsicobiologicos; 

const Diagnostico = db.Diagnostico;
const OrdenesMedicas = db.OrdenesMedicas;

// 1. OBTENER HISTORIA COMPLETA
exports.getHistoriaClinica = async (req, res) => {
    const { cedula } = req.params;

    try {
        const paciente = await Paciente.findOne({
            where: { cedula: cedula },
            include: [
                { model: MotivoConsulta },
                { model: ExamenFisico },
                { model: ExamenFuncional },
                { model: AntecedentesPersonales },
                { model: AntecedentesFamiliares },
                { model: AntecedentesHabitos }, // Sequelize usa la variable que definimos arriba
                { model: Diagnostico },
                { 
                    model: OrdenesMedicas,
                    required: false,
                    where: {} 
                }
            ]
        });

        if (!paciente) {
            return res.status(404).send({ message: "Paciente no encontrado." });
        }

        res.status(200).send(paciente);

    } catch (error) {
        console.error("Error al obtener historia:", error);
        res.status(500).send({ message: "Error interno al cargar la historia clínica." });
    }
};

// 2. ACTUALIZAR O CREAR (UPSERT)
const upsertSeccion = async (Modelo, data, whereClause) => {
    const existe = await Modelo.findOne({ where: whereClause });
    if (existe) {
        return await existe.update(data);
    } else {
        return await Modelo.create({ ...data, ...whereClause });
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
        const where = { cedula_paciente: cedula };

        switch (seccion) {
            case 'datos_personales':
                await Paciente.update(datos, { where: { cedula: cedula } });
                resultado = { message: "Datos personales actualizados." };
                break;
            case 'motivo':
                resultado = await upsertSeccion(MotivoConsulta, datos, where);
                break;
            case 'fisico':
                resultado = await upsertSeccion(ExamenFisico, datos, where);
                break;
            case 'funcional':
                resultado = await upsertSeccion(ExamenFuncional, datos, where);
                break;
            case 'ant_pers':
                resultado = await upsertSeccion(AntecedentesPersonales, datos, where);
                break;
            case 'ant_fam':
                resultado = await upsertSeccion(AntecedentesFamiliares, datos, where);
                break;
            case 'ant_hab':
                // Aquí usamos la variable local que apunta a db.HabitosPsicobiologicos
                resultado = await upsertSeccion(AntecedentesHabitos, datos, where);
                break;
            case 'diagnostico':
                resultado = await upsertSeccion(Diagnostico, datos, where);
                break;
            default:
                return res.status(400).send({ message: "Sección desconocida." });
        }

        res.status(200).send({ message: "Sección guardada correctamente.", data: resultado });

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

        if (!orden) {
            return res.status(404).send({ message: "Orden médica no encontrada." });
        }

        if (orden.estatus !== 'PENDIENTE') {
            return res.status(403).send({ 
                message: `No se puede editar esta orden porque su estatus es ${orden.estatus}.` 
            });
        }

        await orden.update(datosActualizados);

        res.status(200).send({ message: "Orden médica actualizada correctamente.", orden });

    } catch (error) {
        console.error("Error editando orden:", error);
        res.status(500).send({ message: "Error interno al editar la orden." });
    }
};