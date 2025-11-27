const db = require('../models');
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
            include: [{
                model: Paciente,
            }],
            order: [['fecha_orden', 'ASC']]
        });
        res.status(200).send(ordenes);
    } catch (error) {
        console.error("Error al obtener órdenes:", error);
        res.status(500).send({ message: "Error al obtener órdenes pendientes." });
    }
};

// 2. Solicitar Medicamento
exports.solicitarMedicamento = async (req, res) => {
    const { cedula_paciente, id_medicamento, cantidad, id_usuario } = req.body;

    if (!cedula_paciente || !id_medicamento || !cantidad || !id_usuario) {
        return res.status(400).send({ message: "Faltan datos para la solicitud." });
    }

    try {
        // --- VALIDACIONES ---
        const pacienteExiste = await Paciente.findByPk(cedula_paciente);
        if (!pacienteExiste) {
            return res.status(404).send({ 
                message: `Error: La cédula ${cedula_paciente} no corresponde a ningún paciente registrado.` 
            });
        }

        const ordenPendiente = await OrdenesMedicas.findOne({
            where: {
                cedula_paciente: cedula_paciente,
                estatus: 'PENDIENTE'
            }
        });

        if (!ordenPendiente) {
            return res.status(403).send({ 
                message: `Denegado: El paciente ${cedula_paciente} no tiene órdenes médicas pendientes activas.` 
            });
        }

        const medicamento = await Medicamento.findByPk(id_medicamento);
        if (!medicamento) {
            return res.status(404).send({ message: "Medicamento no encontrado en el inventario." });
        }

        if (medicamento.cantidad_disponible < cantidad) {
            return res.status(400).send({ 
                message: `Stock insuficiente. Disponible: ${medicamento.cantidad_disponible}, Solicitado: ${cantidad}` 
            });
        }

        // --- TRANSACCIÓN ---
        const nuevaSolicitud = await SolicitudMedicamento.create({
            cedula_paciente,
            id_medicamento,
            cantidad,
            id_usuario 
        });

        medicamento.cantidad_disponible -= parseInt(cantidad);
        await medicamento.save();

        await MovimientoInventario.create({
            id_medicamento,
            tipo_movimiento: 'SALIDA',
            cantidad,
            motivo: `Solicitud Enfermería - Paciente ${cedula_paciente}`,
            id_usuario
        });

        res.status(201).send({ 
            message: "Medicamento despachado exitosamente.", 
            data: nuevaSolicitud 
        });

    } catch (error) {
        console.error("Error al solicitar medicamento:", error);
        res.status(500).send({ message: "Error al procesar solicitud de medicamento." });
    }
};

// 3. Actualizar Estatus de Orden (Confirmar o Rechazar) - NUEVO
exports.actualizarEstatusOrden = async (req, res) => {
    const { id_orden } = req.params;
    const { estatus, observaciones } = req.body; // Esperamos 'COMPLETADA' o 'NO_REALIZADA'

    if (!estatus) {
        return res.status(400).send({ message: "El estatus es obligatorio." });
    }

    try {
        const orden = await OrdenesMedicas.findByPk(id_orden);
        
        if (!orden) {
            return res.status(404).send({ message: "Orden médica no encontrada." });
        }

        // Actualizamos los campos
        orden.estatus = estatus;
        orden.observaciones_cumplimiento = observaciones;
        orden.fecha_cumplimiento = new Date(); // Guardamos el momento exacto
        
        await orden.save();

        res.status(200).send({ 
            message: `Orden actualizada a: ${estatus}`,
            orden: orden
        });

    } catch (error) {
        console.error("Error al actualizar orden:", error);
        res.status(500).send({ message: "Error interno al actualizar la orden." });
    }
};