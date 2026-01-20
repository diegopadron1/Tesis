const db = require('../models');
const Medicamento = db.Medicamento;
const MovimientoInventario = db.MovimientoInventario;
const SolicitudMedicamento = db.SolicitudMedicamento; 
const Usuario = db.user; 
const { Op } = require("sequelize");

// 1. Ver inventario (CON FILTRO DE STOCK PARA BÚSQUEDAS)
exports.getMedicamentos = async (req, res) => {
    try {
        const { q } = req.query; 
        let whereClause = {};
        if (q) {
            whereClause = {
                [Op.and]: [
                    {
                        [Op.or]: [
                            { nombre: { [Op.iLike]: `%${q}%` } },
                            { principio_activo: { [Op.iLike]: `%${q}%` } }
                        ]
                    },
                    {
                        cantidad_disponible: { [Op.gt]: 0 } 
                    }
                ]
            };
        }
        const medicamentos = await Medicamento.findAll({
            where: whereClause,
            order: [['nombre', 'ASC']]
        });
        
        res.status(200).send(medicamentos);
    } catch (error) {
        console.error("Error en getMedicamentos:", error);
        res.status(500).send({ message: "Error al obtener inventario." });
    }
};

// --- BÚSQUEDA PARA AUTOCOMPLETE ---
exports.searchMedicamentos = async (req, res) => {
    try {
        const { nombre } = req.query;
        const medicamentos = await Medicamento.findAll({
            where: {
                [Op.or]: [
                    { nombre: { [Op.iLike]: `%${nombre}%` } },
                    { principio_activo: { [Op.iLike]: `%${nombre}%` } }
                ]
            },
            limit: 8,
            order: [['nombre', 'ASC']]
        });
        res.status(200).send(medicamentos);
    } catch (error) {
        res.status(500).send({ message: "Error en búsqueda: " + error.message });
    }
};

// 2. Crear Medicamento
exports.crearMedicamento = async (req, res) => {
    try {
        const { nombre, principio_activo, concentracion, presentacion, stock_minimo, fecha_vencimiento } = req.body;
        if (!nombre) {
            return res.status(400).send({ message: "El nombre es obligatorio." });
        }
        const fechaFinal = (fecha_vencimiento && fecha_vencimiento !== "") ? fecha_vencimiento : null;
        const medicamentoExistente = await Medicamento.findOne({
            where: {
                nombre: nombre,
                concentracion: concentracion,
                fecha_vencimiento: fechaFinal
            }
        });
        if (medicamentoExistente) {
            return res.status(400).send({ 
                message: "Ya existe un registro de este medicamento con la misma concentración y fecha de vencimiento. Si desea añadir stock, utilice la opción de '+' en el inventario." 
            });
        }
        const nuevo = await Medicamento.create({
            nombre,
            principio_activo,
            concentracion,
            presentacion,
            cantidad_disponible: 0,
            stock_minimo: stock_minimo || 10,
            fecha_vencimiento: fechaFinal
        });
        res.status(201).send({ message: "Medicamento registrado exitosamente.", data: nuevo });
    } catch (error) {
        console.error("Error al crear:", error);
        res.status(500).send({ message: error.message || "Error al crear medicamento." });
    }
};

// 3. Actualizar Stock (Maneja Entrada y Salida)
exports.actualizarStock = async (req, res) => {
    const { cantidad, tipo_movimiento, motivo, id_usuario } = req.body; 
    const { id } = req.params;
    if (!id || !cantidad || cantidad <= 0 || !tipo_movimiento) {
        return res.status(400).send({ message: "Datos incompletos." });
    }
    try {
        const medicamento = await Medicamento.findByPk(id);
        if (!medicamento) return res.status(404).send({ message: "Medicamento no encontrado." });
        if (tipo_movimiento === 'ENTRADA') {
            medicamento.cantidad_disponible += parseInt(cantidad);
            await MovimientoInventario.create({
                id_medicamento: id,
                tipo_movimiento: 'ENTRADA',
                cantidad,
                motivo: motivo || 'Reposición',
                id_usuario
            });
        } else if (tipo_movimiento === 'SALIDA') {
            if (medicamento.cantidad_disponible < cantidad) {
                return res.status(400).send({ message: `Stock insuficiente. Disponible: ${medicamento.cantidad_disponible}` });
            }
            medicamento.cantidad_disponible -= parseInt(cantidad);
            await MovimientoInventario.create({
                id_medicamento: id,
                tipo_movimiento: 'SALIDA',
                cantidad,
                motivo: motivo || 'Salida',
                id_usuario
            });
        }
        await medicamento.save();
        res.status(200).send({ message: "Inventario actualizado.", nuevo_stock: medicamento.cantidad_disponible });
    } catch (error) {
        res.status(500).send({ message: "Error al actualizar stock." });
    }
};

// 4. Eliminar Medicamento
exports.eliminarMedicamento = async (req, res) => {
    const { id } = req.params;
    try {
        const resultado = await Medicamento.destroy({ where: { id_medicamento: id } });
        if (resultado == 1) res.send({ message: "Eliminado correctamente." });
        else res.status(404).send({ message: "No encontrado." });
    } catch (error) {
        res.status(500).send({ message: "No se pudo eliminar (probablemente tiene historial)." });
    }
};

// =========================================================
//  NUEVAS FUNCIONES PARA EL FLUJO DE FARMACIA
// =========================================================

// 5. Obtener Solicitudes (MODIFICADO: Trae PENDIENTE y LISTO)
exports.getSolicitudesPendientes = async (req, res) => {
    try {
        console.log("--> Buscando solicitudes activas para farmacia...");
        
        const lista = await SolicitudMedicamento.findAll({
            // El widget NO se va de la vista hasta que el estatus sea 'ENTREGADO'
            where: { 
                estatus: { [Op.in]: ['PENDIENTE', 'LISTO'] } 
            },
            include: [
                {
                    model: Medicamento,
                    as: 'medicamento', 
                    attributes: ['nombre', 'concentracion', 'presentacion']
                },
                {
                    model: Usuario,
                    as: 'usuario_solicitante', 
                }
            ],
            // Ordenamos: PENDIENTE primero para preparación, luego LISTO para entrega
            order: [['estatus', 'DESC'], ['fecha_solicitud', 'ASC']]
        });

        const respuesta = lista.map(s => {
            const data = s.toJSON();
            const usuario = data.usuario_solicitante || {};
            
            let nombreMostrar = 'Desconocido';

            if (usuario.nombre_completo) {
                nombreMostrar = usuario.nombre_completo;
            } else if (usuario.nombre && usuario.apellido) {
                nombreMostrar = `${usuario.nombre} ${usuario.apellido}`;
            } else if (usuario.nombre_usuario) {
                nombreMostrar = usuario.nombre_usuario;
            }

            return {
                ...data,
                usuario_solicitante: {
                    nombre_completo: nombreMostrar
                }
            };
        });

        res.status(200).send(respuesta);
    } catch (error) {
        console.error("Error getSolicitudesPendientes:", error);
        res.status(500).send({ message: "Error al obtener solicitudes: " + error.message });
    }
};

// 6. Actualizar Estado (Genérico: PENDIENTE -> LISTO -> ENTREGADO)
exports.actualizarEstado = async (req, res) => {
    try {
        const { id } = req.params; 
        const { estatus } = req.body; // Recibe 'LISTO' o 'ENTREGADO'
        const solicitud = await SolicitudMedicamento.findByPk(id);
        
        if (!solicitud) return res.status(404).send({ message: "Solicitud no encontrada" });

        solicitud.estatus = estatus;
        await solicitud.save();

        res.status(200).send({ 
            success: true, 
            message: `Solicitud actualizada a ${estatus}.` 
        });
    } catch (error) {
        res.status(500).send({ message: "Error al procesar: " + error.message });
    }
};

// 7. Marcar solicitud como LISTA (Mantener por compatibilidad si es necesario)
exports.marcarListo = async (req, res) => {
    req.body.estatus = 'LISTO';
    return exports.actualizarEstado(req, res);
};