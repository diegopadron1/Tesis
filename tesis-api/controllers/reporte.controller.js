const db = require('../models');
const Triaje = db.Triaje;
const OrdenesMedicas = db.OrdenesMedicas;
const SolicitudMedicamento = db.SolicitudMedicamento;
const { Op, fn, col } = require("sequelize");

exports.getReportePacientesPorDia = async (req, res) => {
    try {
        const { fecha } = req.query; 
        if (!fecha) return res.status(400).send({ message: "Debe proporcionar una fecha." });

        // Ajuste de zona horaria local
        const [year, month, day] = fecha.split('-').map(Number);
        const inicioDia = new Date(year, month - 1, day, 0, 0, 0, 0);
        const finDia = new Date(year, month - 1, day, 23, 59, 59, 999);

        // --- 1. MÉTRICAS DE PACIENTES ---
        const totalAtendidos = await Triaje.count({
            where: { 
                updatedAt: { [Op.between]: [inicioDia, finDia] },
                estado: { [Op.ne]: 'En Espera' }
            }
        });

        const altas = await Triaje.count({
            where: {
                updatedAt: { [Op.between]: [inicioDia, finDia] },
                estado: 'Alta'
            }
        });

        const fallecidos = await Triaje.count({
            where: {
                updatedAt: { [Op.between]: [inicioDia, finDia] },
                estado: 'Fallecido'
            }
        });

        // --- 2. MÉTRICAS DE ÓRDENES MÉDICAS ---
        const ordenesRealizadas = await OrdenesMedicas.count({
            where: {
                updatedAt: { [Op.between]: [inicioDia, finDia] },
                estatus: { [Op.in]: ['REALIZADA', 'COMPLETADA'] } 
            }
        });

        const ordenesPendientes = await OrdenesMedicas.count({
            where: {
                createdAt: { [Op.between]: [inicioDia, finDia] },
                estatus: 'PENDIENTE'
            }
        });

        const ordenesCanceladas = await OrdenesMedicas.count({
            where: {
                updatedAt: { [Op.between]: [inicioDia, finDia] },
                estatus: 'CANCELADA'
            }
        });

        const ordenesNoRealizadas = await OrdenesMedicas.count({
            where: {
                updatedAt: { [Op.between]: [inicioDia, finDia] },
                estatus: 'NO_REALIZADA'
            }
        });

        // --- 3. MÉTRICAS DE SOLICITUDES ---
        const totalSolicitudes = await SolicitudMedicamento.count({
            where: {
                fecha_solicitud: { [Op.between]: [inicioDia, finDia] }
            }
        });

        // --- 4. DISTRIBUCIÓN POR ÁREA ---
        const porArea = await Triaje.findAll({
            where: { 
                updatedAt: { [Op.between]: [inicioDia, finDia] },
                estado: { [Op.ne]: 'En Espera' }
            },
            attributes: [
                'ubicacion',
                [fn('COUNT', col('id_triaje')), 'cantidad']
            ],
            group: ['ubicacion']
        });

        res.status(200).send({
            fecha: fecha,
            metricas: {
                total_atendidos: totalAtendidos,
                altas: altas,
                fallecidos: fallecidos,
                ordenes_realizadas: ordenesRealizadas,
                ordenes_pendientes: ordenesPendientes,
                ordenes_canceladas: ordenesCanceladas,
                ordenes_no_realizadas: ordenesNoRealizadas,
                total_solicitudes: totalSolicitudes
            },
            distribucion_areas: porArea
        });

    } catch (error) {
        console.error("Error en reporte integral:", error);
        res.status(500).send({ message: "Error al generar reporte." });
    }
};