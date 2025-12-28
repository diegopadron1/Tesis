const db = require('../models');
const { Op } = require("sequelize");
const OrdenesMedicas = db.OrdenesMedicas;
const Medicamento = db.Medicamento;
const SolicitudMedicamento = db.SolicitudMedicamento;
const MovimientoInventario = db.MovimientoInventario;
const Paciente = db.Paciente;
const Triaje = db.Triaje; 

// 1. Obtener Órdenes Médicas Pendientes (LÓGICA CORREGIDA SIN ASOCIACIÓN)
exports.getOrdenesPendientes = async (req, res) => {
    try {
        // PASO A: Buscar qué carpetas tienen pacientes "Siendo Atendido"
        const triajesEnAtencion = await Triaje.findAll({
            where: { estado: 'Siendo Atendido' },
            attributes: ['id_carpeta'],
            raw: true
        });

        // Extraemos solo los IDs de las carpetas
        const idsCarpetasActivas = triajesEnAtencion.map(t => t.id_carpeta);

        // Si no hay nadie siendo atendido, devolvemos lista vacía de inmediato
        if (idsCarpetasActivas.length === 0) {
            return res.status(200).send([]);
        }

        // PASO B: Buscar las órdenes que pertenezcan a esas carpetas
        const ordenes = await OrdenesMedicas.findAll({
            where: { 
                estatus: 'PENDIENTE',
                id_carpeta: { [Op.in]: idsCarpetasActivas } // Solo carpetas en atención
            },
            include: [
                { model: Paciente },
                { 
                    model: db.Medicamento, 
                    as: 'medicamento', 
                    attributes: ['nombre', 'concentracion'] 
                }
            ],
            order: [['createdAt', 'ASC']]
        });

        res.status(200).send(ordenes);
    } catch (error) {
        console.error("Error al obtener órdenes filtradas:", error);
        res.status(500).send({ message: "Error al obtener órdenes." });
    }
};

// 2. Solicitar Medicamento (CORREGIDO)
exports.solicitarMedicamento = async (req, res) => {
    const { cedula_paciente, id_medicamento, cantidad, id_usuario } = req.body;

    try {
        // 1. Buscamos la orden PENDIENTE activa
        const ordenPendiente = await OrdenesMedicas.findOne({
            where: {
                cedula_paciente: cedula_paciente.trim(),
                estatus: 'PENDIENTE'
            },
            order: [['createdAt', 'DESC']]
        });

        if (!ordenPendiente) {
            return res.status(403).send({ success: false, message: "No hay órdenes pendientes." });
        }

        // 2. VALIDACIÓN DE ATENCIÓN: ¿El paciente de esta orden está en atención?
        const estaEnAtencion = await Triaje.findOne({
            where: { 
                id_carpeta: ordenPendiente.id_carpeta,
                estado: 'Siendo Atendido'
            }
        });

        if (!estaEnAtencion) {
            return res.status(403).send({ 
                success: false, 
                message: "DENIEGO: El paciente debe estar en estado 'Siendo Atendido' para despachar fármacos." 
            });
        }

        // 3. CANDADO DE SOLICITUD ÚNICA
        const solicitudExistente = await SolicitudMedicamento.findOne({
            where: { id_orden: ordenPendiente.id_orden }
        });

        if (solicitudExistente) {
            return res.status(400).send({ success: false, message: "Ya existe una solicitud para esta orden." });
        }

        // 4. VALIDACIÓN DE MEDICAMENTO Y STOCK
        if (Number(ordenPendiente.id_medicamento) !== Number(id_medicamento)) {
            return res.status(403).send({ success: false, message: "Medicamento no coincide con la receta." });
        }

        const medicamento = await Medicamento.findByPk(id_medicamento);
        if (!medicamento || medicamento.cantidad_disponible < Number(cantidad)) {
            return res.status(400).send({ message: "Stock insuficiente." });
        }

        // 5. PROCESAR
        const nuevaSolicitud = await SolicitudMedicamento.create({
            cedula_paciente,
            id_medicamento: Number(id_medicamento),
            id_orden: ordenPendiente.id_orden,
            cantidad: Number(cantidad),
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

        res.status(201).send({ success: true, message: "Solicitud procesada.", data: nuevaSolicitud });

    } catch (error) {
        console.error("ERROR EN SOLICITUD:", error);
        res.status(500).send({ message: "Error interno del servidor." });
    }
};

// 3. Actualizar Estatus de Orden (Queda igual, es seguro)
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

// 4. Obtener medicamento autorizado (CORREGIDO)
exports.getMedicamentoAutorizado = async (req, res) => {
    const { cedula } = req.params;
    try {
        const orden = await OrdenesMedicas.findOne({
            where: { cedula_paciente: cedula, estatus: 'PENDIENTE' },
            include: [{ model: Medicamento, as: 'medicamento' }],
            order: [['createdAt', 'DESC']]
        });

        if (!orden) return res.status(404).send({ message: "No hay órdenes pendientes." });

        // Validar si está en atención antes de dar la info
        const enAtencion = await Triaje.findOne({
            where: { id_carpeta: orden.id_carpeta, estado: 'Siendo Atendido' }
        });

        if (!enAtencion) {
            return res.status(403).send({ message: "El paciente aún no está en atención médica." });
        }

        res.status(200).send({
            id_medicamento: orden.id_medicamento,
            nombre: orden.medicamento.nombre,
            concentracion: orden.medicamento.concentracion,
            dosis_recetada: orden.requerimiento_medicamentos
        });
    } catch (error) {
        res.status(500).send({ message: "Error al consultar la orden." });
    }
};