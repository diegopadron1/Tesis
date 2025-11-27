const db = require('../models');
const Medicamento = db.Medicamento;
const MovimientoInventario = db.MovimientoInventario;

// 1. Ver inventario
exports.getMedicamentos = async (req, res) => {
    try {
        const medicamentos = await Medicamento.findAll({
            order: [['nombre', 'ASC']]
        });
        res.status(200).send(medicamentos);
    } catch (error) {
        res.status(500).send({ message: "Error al obtener inventario." });
    }
};

// 2. Crear Medicamento (Tu lógica original restaurada)
exports.crearMedicamento = async (req, res) => {
    try {
        const { nombre, principio_activo, concentracion, presentacion, stock_minimo, fecha_vencimiento } = req.body;

        if (!nombre) {
            return res.status(400).send({ message: "El nombre es obligatorio." });
        }

        // Validación: Si la fecha viene vacía, la convertimos a NULL para que PostgreSQL no falle
        const fechaFinal = (fecha_vencimiento && fecha_vencimiento !== "") ? fecha_vencimiento : null;

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

// 3. Actualizar Stock (Inteligente: Maneja Entrada y Salida)
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