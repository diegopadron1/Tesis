const db = require('../models');
const { Op } = require("sequelize");
const OrdenesMedicas = db.OrdenesMedicas;
const Medicamento = db.Medicamento;
const SolicitudMedicamento = db.SolicitudMedicamento;
const MovimientoInventario = db.MovimientoInventario;
const Paciente = db.Paciente; 

// 1. Obtener Órdenes Médicas Pendientes
exports.getOrdenesPendientes = async (req, res) => {
    try {
        const ordenes = await OrdenesMedicas.findAll({
            where: { estatus: 'PENDIENTE' },
            include: [
                { model: Paciente },
                { 
                    model: db.Medicamento, 
                    as: 'medicamento', 
                    attributes: ['nombre', 'concentracion'] 
                }
            ],
            order: [['createdAt', 'ASC']] // Cambiado a createdAt para consistencia
        });
        res.status(200).send(ordenes);
    } catch (error) {
        console.error("Error al obtener órdenes:", error);
        res.status(500).send({ message: "Error al obtener órdenes pendientes." });
    }
};

// 2. Solicitar Medicamento (CON VALIDACIÓN DE SOLICITUD ÚNICA)
exports.solicitarMedicamento = async (req, res) => {
    const { cedula_paciente, id_medicamento, cantidad, id_usuario } = req.body;

    console.log(`--- Intento de Solicitud ---`);
    console.log(`Paciente: ${cedula_paciente} | MedID: ${id_medicamento}`);

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
            return res.status(403).send({ 
                success: false,
                message: `Denegado: No hay órdenes pendientes para la cédula ${cedula_paciente}.` 
            });
        }

        // ============================================================
        // NUEVA VALIDACIÓN: CANDADO DE SOLICITUD ÚNICA POR ORDEN
        // ============================================================
        const solicitudExistente = await SolicitudMedicamento.findOne({
            where: { id_orden: ordenPendiente.id_orden }
        });

        if (solicitudExistente) {
            console.log(`❌ BLOQUEO: La orden #${ordenPendiente.id_orden} ya tiene una solicitud previa.`);
            return res.status(400).send({ 
                success: false,
                message: "BLOQUEO DE SEGURIDAD: Ya existe una solicitud de fármacos para esta orden médica. No se permite duplicar el despacho." 
            });
        }
        // ============================================================

        // 2. VERIFICACIÓN DE SEGURIDAD (Medicamento correcto)
        if (Number(ordenPendiente.id_medicamento) !== Number(id_medicamento)) {
            const medAutorizado = await Medicamento.findByPk(ordenPendiente.id_medicamento);
            const nombreAutorizado = medAutorizado ? medAutorizado.nombre : "desconocido";

            return res.status(403).send({ 
                success: false,
                message: `Medicamento no autorizado. El médico recetó: ${nombreAutorizado}.` 
            });
        }

        // 3. VALIDACIÓN DE STOCK
        const medicamento = await Medicamento.findByPk(id_medicamento);
        if (!medicamento) return res.status(404).send({ message: "Medicamento no existe en inventario." });

        if (medicamento.cantidad_disponible < Number(cantidad)) {
            return res.status(400).send({ message: `Stock insuficiente en farmacia (${medicamento.cantidad_disponible}).` });
        }

        // 4. CREAR SOLICITUD
        const nuevaSolicitud = await SolicitudMedicamento.create({
            cedula_paciente,
            id_medicamento: Number(id_medicamento),
            id_orden: ordenPendiente.id_orden,
            cantidad: Number(cantidad),
            id_usuario 
        });

        // Actualizar stock
        medicamento.cantidad_disponible = (medicamento.cantidad_disponible || 0) - Number(cantidad);
        await medicamento.save();

        // Registrar el movimiento para el historial
        await MovimientoInventario.create({
            id_medicamento: Number(id_medicamento),
            tipo_movimiento: 'SALIDA',
            cantidad: Number(cantidad),
            motivo: `Despacho Orden #${ordenPendiente.id_orden} - Enfermería`,
            id_usuario
        });

        res.status(201).send({ 
            success: true,
            message: "Solicitud procesada correctamente y stock descontado.", 
            data: nuevaSolicitud 
        });

    } catch (error) {
        console.error("ERROR CRÍTICO:", error);
        res.status(500).send({ message: "Error interno al procesar la solicitud." });
    }
};

// 3. Actualizar Estatus de Orden (Confirmar o Rechazar)
exports.actualizarEstatusOrden = async (req, res) => {
    const { id_orden } = req.params;
    const { estatus, observaciones, id_usuario } = req.body; 

    if (!estatus) return res.status(400).send({ message: "El estatus es obligatorio." });

    try {
        const orden = await OrdenesMedicas.findByPk(id_orden);
        if (!orden) return res.status(404).send({ message: "Orden médica no encontrada." });

        // Si se cancela la orden, devolvemos el stock solicitado
        if (estatus === 'NO_REALIZADA') {
            const solicitudes = await SolicitudMedicamento.findAll({ 
                where: { id_orden: id_orden } 
            });

            for (const solicitud of solicitudes) {
                const med = await Medicamento.findByPk(solicitud.id_medicamento);
                if (med) {
                    med.cantidad_disponible += solicitud.cantidad;
                    await med.save();

                    await MovimientoInventario.create({
                        id_medicamento: med.id_medicamento,
                        tipo_movimiento: 'ENTRADA',
                        cantidad: solicitud.cantidad,
                        motivo: `REVERSIÓN: Orden #${id_orden} cancelada/rechazada`,
                        id_usuario: id_usuario || null
                    });
                }
            }
        }

        orden.estatus = estatus;
        orden.observaciones_cumplimiento = observaciones;
        orden.fecha_cumplimiento = new Date();
        await orden.save();

        res.status(200).send({ 
            success: true,
            message: estatus === 'NO_REALIZADA' 
                ? "Orden rechazada y medicamentos devueltos al inventario." 
                : `Orden actualizada a: ${estatus}`,
            orden: orden
        });

    } catch (error) {
        console.error("Error al actualizar orden:", error);
        res.status(500).send({ message: "Error interno al actualizar la orden." });
    }
};

// 4. Obtener medicamento autorizado de la orden activa
exports.getMedicamentoAutorizado = async (req, res) => {
    const { cedula } = req.params;
    try {
        const orden = await OrdenesMedicas.findOne({
            where: { cedula_paciente: cedula, estatus: 'PENDIENTE' },
            include: [{ 
                model: Medicamento, 
                as: 'medicamento'
            }],
            order: [['createdAt', 'DESC']]
        });

        if (!orden) {
            return res.status(404).send({ message: "No se encontró una orden pendiente." });
        }

        res.status(200).send({
            id_medicamento: orden.id_medicamento,
            nombre: orden.medicamento.nombre,
            concentracion: orden.medicamento.concentracion,
            dosis_recetada: orden.requerimiento_medicamentos
        });
    } catch (error) {
        res.status(500).send({ message: "Error al consultar la orden activa." });
    }
};