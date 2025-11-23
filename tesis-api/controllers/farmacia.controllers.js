const db = require('../models');
const Medicamento = db.Medicamento;
const MovimientoInventario = db.MovimientoInventario;

// 1. Registrar un nuevo medicamento (Catálogo)
exports.createMedicamento = async (req, res) => {
    try {
        const { nombre, principio_activo, concentracion, presentacion, stock_minimo, fecha_vencimiento } = req.body;

        if (!nombre) {
            return res.status(400).send({ message: "El nombre es obligatorio." });
        }

        const nuevo = await Medicamento.create({
            nombre,
            principio_activo,
            concentracion,
            presentacion,
            cantidad_disponible: 0, 
            stock_minimo,
            fecha_vencimiento // Sequelize lo guarda si viene en formato 'YYYY-MM-DD'
        });

        res.status(201).send({ message: "Medicamento registrado en catálogo.", data: nuevo });
    } catch (error) {
        res.status(500).send({ message: error.message || "Error al crear medicamento." });
    }
};

// 2. Ver todo el inventario
exports.getAllMedicamentos = async (req, res) => {
    try {
        const medicamentos = await Medicamento.findAll({
            order: [['nombre', 'ASC']]
        });
        res.status(200).send(medicamentos);
    } catch (error) {
        res.status(500).send({ message: error.message || "Error al obtener inventario." });
    }
};

// 3. Agregar Stock (Entrada)
exports.addStock = async (req, res) => {
    const { id_medicamento, cantidad, motivo } = req.body;

    if (!id_medicamento || !cantidad || cantidad <= 0) {
        return res.status(400).send({ message: "Datos inválidos para entrada de stock." });
    }

    try {
        const medicamento = await Medicamento.findByPk(id_medicamento);
        if (!medicamento) return res.status(404).send({ message: "Medicamento no encontrado." });

        await MovimientoInventario.create({
            id_medicamento,
            tipo_movimiento: 'ENTRADA',
            cantidad,
            motivo: motivo || 'Reposición de inventario'
        });

        medicamento.cantidad_disponible += parseInt(cantidad);
        await medicamento.save();

        res.status(200).send({ message: "Stock agregado correctamente.", nuevo_stock: medicamento.cantidad_disponible });
    } catch (error) {
        res.status(500).send({ message: error.message || "Error al actualizar stock." });
    }
};

// 4. Quitar Stock (Salida) - NUEVA FUNCIÓN
exports.removeStock = async (req, res) => {
    const { id_medicamento, cantidad, motivo } = req.body;

    if (!id_medicamento || !cantidad || cantidad <= 0) {
        return res.status(400).send({ message: "Datos inválidos para salida de stock." });
    }

    try {
        const medicamento = await Medicamento.findByPk(id_medicamento);
        if (!medicamento) return res.status(404).send({ message: "Medicamento no encontrado." });

        // VALIDACIÓN DE STOCK SUFICIENTE
        if (medicamento.cantidad_disponible < cantidad) {
            return res.status(400).send({ message: "No hay suficiente stock para realizar esta salida." });
        }

        await MovimientoInventario.create({
            id_medicamento,
            tipo_movimiento: 'SALIDA',
            cantidad,
            motivo: motivo || 'Ajuste de inventario / Salida manual'
        });

        medicamento.cantidad_disponible -= parseInt(cantidad);
        await medicamento.save();

        res.status(200).send({ message: "Stock descontado correctamente.", nuevo_stock: medicamento.cantidad_disponible });
    } catch (error) {
        res.status(500).send({ message: error.message || "Error al actualizar stock." });
    }
};