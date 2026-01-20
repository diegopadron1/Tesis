const db = require('../models');
const { Op } = require("sequelize");
const OrdenesMedicas = db.OrdenesMedicas;
const Medicamento = db.Medicamento;
const SolicitudMedicamento = db.SolicitudMedicamento;
const MovimientoInventario = db.MovimientoInventario;
const Paciente = db.Paciente;
const Triaje = db.Triaje; 

// 1. Obtener Órdenes Médicas Pendientes
exports.getOrdenesPendientes = async (req, res) => {
    try {
        const triajesEnAtencion = await Triaje.findAll({
            where: { estado: 'Siendo Atendido' },
            attributes: ['id_carpeta', 'ubicacion'], 
            raw: true
        });

        if (triajesEnAtencion.length === 0) {
            return res.status(200).send([]);
        }

        const mapaUbicaciones = {};
        const idsCarpetasActivas = [];

        triajesEnAtencion.forEach(t => {
            mapaUbicaciones[t.id_carpeta] = t.ubicacion;
            idsCarpetasActivas.push(t.id_carpeta);
        });

        const ordenes = await OrdenesMedicas.findAll({
            where: { 
                estatus: 'PENDIENTE',
                id_carpeta: { [Op.in]: idsCarpetasActivas } 
            },
            include: [
                { model: Paciente },
                { 
                    model: db.Medicamento, 
                    as: 'medicamento', 
                    attributes: ['nombre', 'concentracion'] 
                },
                {
                    model: SolicitudMedicamento,
                    // CAMBIO CLAVE AQUÍ: Usamos el alias 'solicitudes' que es el que Sequelize reporta
                    as: 'solicitudes', 
                    required: false, 
                    where: { estatus: { [Op.in]: ['PENDIENTE', 'LISTO', 'ENTREGADO'] } },
                    include: [{ 
                        model: db.Medicamento, 
                        as: 'medicamento', 
                        attributes: ['nombre'] 
                    }] 
                }
            ],
            order: [['createdAt', 'ASC']]
        });

        const resultados = ordenes.map(orden => {
            const ordenJson = orden.toJSON();
            ordenJson.ubicacion = mapaUbicaciones[orden.id_carpeta] || 'Ubicación no asignada';
            
            if(ordenJson.Paciente) {
                ordenJson.cedula_paciente = ordenJson.Paciente.cedula; 
            }

            // Normalizamos el nombre para el frontend (la App espera 'SolicitudMedicamentos')
            // para no tener que cambiar la lógica de la App, renombramos la propiedad aquí
            ordenJson.SolicitudMedicamentos = ordenJson.solicitudes || [];
            delete ordenJson.solicitudes;

            return ordenJson;
        });

        res.status(200).send(resultados);

    } catch (error) {
        console.error("Error al obtener órdenes filtradas:", error);
        res.status(500).send({ message: error.message });
    }
};

// 2. Solicitar Medicamento (CARRITO MÚLTIPLE)
exports.solicitarMedicamento = async (req, res) => {
    const { cedula_paciente, id_medicamento, cantidad, id_usuario } = req.body;

    try {
        const ordenPendiente = await OrdenesMedicas.findOne({
            where: {
                cedula_paciente: cedula_paciente.trim(),
                estatus: 'PENDIENTE'
            },
            order: [['createdAt', 'DESC']]
        });

        if (!ordenPendiente) {
            return res.status(403).send({ success: false, message: "No hay órdenes médicas activas." });
        }

        const estaEnAtencion = await Triaje.findOne({
            where: { 
                id_carpeta: ordenPendiente.id_carpeta,
                estado: 'Siendo Atendido'
            }
        });

        if (!estaEnAtencion) {
            return res.status(403).send({ 
                success: false, 
                message: "El paciente debe estar en 'Siendo Atendido'." 
            });
        }

        const solicitudExistente = await SolicitudMedicamento.findOne({
            where: { 
                id_orden: ordenPendiente.id_orden,
                id_medicamento: id_medicamento,
                estatus: { [Op.in]: ['PENDIENTE', 'LISTO'] }
            }
        });

        if (solicitudExistente) {
            return res.status(400).send({ success: false, message: "Ya existe una solicitud activa para este fármaco." });
        }

        const medicamento = await Medicamento.findByPk(id_medicamento);
        if (!medicamento || medicamento.cantidad_disponible < Number(cantidad)) {
            return res.status(400).send({ success: false, message: "Stock insuficiente en farmacia." });
        }

        const nuevaSolicitud = await SolicitudMedicamento.create({
            cedula_paciente,
            id_medicamento: Number(id_medicamento),
            id_orden: ordenPendiente.id_orden,
            cantidad: Number(cantidad),
            estatus: 'PENDIENTE', 
            id_usuario 
        });

        medicamento.cantidad_disponible -= Number(cantidad);
        await medicamento.save();

        await MovimientoInventario.create({
            id_medicamento: Number(id_medicamento),
            tipo_movimiento: 'SALIDA',
            cantidad: Number(cantidad),
            motivo: `Despacho Orden #${ordenPendiente.id_orden}`,
            id_usuario
        });

        res.status(201).send({ success: true, message: "Solicitud enviada a farmacia.", data: nuevaSolicitud });

    } catch (error) {
        console.error("ERROR EN SOLICITUD:", error);
        res.status(500).send({ message: "Error interno: " + error.message });
    }
};

// 3. Actualizar Estatus de Orden (SUMINISTRADO / NO REALIZADO)
exports.actualizarEstatusOrden = async (req, res) => {
    const { id_orden } = req.params;
    const { estatus, observaciones, id_usuario } = req.body; 
    try {
        const orden = await OrdenesMedicas.findByPk(id_orden);
        if (!orden) return res.status(404).send({ message: "Orden no encontrada." });

        if (estatus === 'NO_REALIZADA') {
            const solicitudes = await SolicitudMedicamento.findAll({ where: { id_orden } });
            for (const sol of solicitudes) {
                const med = await Medicamento.findByPk(sol.id_medicamento);
                if (med) {
                    med.cantidad_disponible += sol.cantidad;
                    await med.save();
                    await MovimientoInventario.create({
                        id_medicamento: med.id_medicamento,
                        tipo_movimiento: 'ENTRADA',
                        cantidad: sol.cantidad,
                        motivo: `REVERSIÓN: Orden #${id_orden} cancelada`,
                        id_usuario: id_usuario || null
                    });
                }
            }
        }

        orden.estatus = estatus;
        orden.observaciones_cumplimiento = observaciones;
        orden.fecha_cumplimiento = new Date();
        await orden.save();
        res.status(200).send({ success: true, message: `Orden actualizada a: ${estatus}` });
    } catch (error) {
        res.status(500).send({ message: "Error al actualizar." });
    }
};

// 4. Obtener medicamento autorizado
exports.getMedicamentoAutorizado = async (req, res) => {
    const { cedula } = req.params;
    try {
        const orden = await OrdenesMedicas.findOne({
            where: { cedula_paciente: cedula, estatus: 'PENDIENTE' },
            include: [{ model: Medicamento, as: 'medicamento' }],
            order: [['createdAt', 'DESC']]
        });

        if (!orden) return res.status(404).send({ message: "No hay órdenes pendientes." });

        const enAtencion = await Triaje.findOne({
            where: { id_carpeta: orden.id_carpeta, estado: 'Siendo Atendido' }
        });

        if (!enAtencion) {
            return res.status(403).send({ message: "El paciente aún no está en atención médica." });
        }

        res.status(200).send({
            id_medicamento: orden.id_medicamento,
            nombre: orden.medicamento ? orden.medicamento.nombre : "Varios",
            concentracion: orden.medicamento ? orden.medicamento.concentracion : "",
            dosis_recetada: orden.requerimiento_medicamentos
        });
    } catch (error) {
        res.status(500).send({ message: "Error al consultar la orden." });
    }
};

// 5. Obtener Solicitudes para vista de Farmacia
exports.getSolicitudesFarmacia = async (req, res) => {
    try {
        const solicitudes = await SolicitudMedicamento.findAll({
            where: { estatus: { [Op.in]: ['PENDIENTE', 'LISTO'] } },
            include: [
                { model: Medicamento, as: 'medicamento' },
                { model: db.Usuario, as: 'usuario_solicitante', attributes: ['nombre_completo'] }
            ],
            order: [['estatus', 'DESC'], ['createdAt', 'ASC']] 
        });
        res.status(200).send(solicitudes);
    } catch (error) {
        res.status(500).send({ success: false, message: "Error al obtener solicitudes." });
    }
};

// 6. Actualizar estatus de una SOLICITUD individual
exports.actualizarEstatusSolicitud = async (req, res) => {
    const { id_solicitud } = req.params;
    const { estatus } = req.body; 

    try {
        const solicitud = await SolicitudMedicamento.findByPk(id_solicitud);
        if (!solicitud) return res.status(404).send({ message: "Solicitud no encontrada." });

        solicitud.estatus = estatus;
        await solicitud.save();

        res.status(200).send({ success: true, message: `Estado actualizado a: ${estatus}` });
    } catch (error) {
        res.status(500).send({ message: "Error al actualizar solicitud." });
    }
};