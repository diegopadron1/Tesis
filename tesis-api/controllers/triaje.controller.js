const db = require('../models');
const Triaje = db.Triaje;
const Paciente = db.Paciente; 
const Sequelize = db.Sequelize;

// Registrar un nuevo Triaje
exports.createTriaje = async (req, res) => {
    try {
        const { cedula_paciente, color, ubicacion, motivo_ingreso, signos_vitales } = req.body;

        const pacienteExistente = await Paciente.findOne({ where: { cedula: cedula_paciente } });

        if (!pacienteExistente) {
            return res.status(404).send({ message: "Paciente no encontrado. Regístrelo primero." });
        }

        const nuevoTriaje = await Triaje.create({
            cedula_paciente,
            color,
            ubicacion,
            motivo_ingreso,
            signos_vitales,
            estado: 'En Espera'
        });

        res.status(201).send({ message: "Triaje registrado.", data: nuevoTriaje });
    } catch (error) {
        console.error("Error createTriaje:", error);
        res.status(500).send({ message: "Error DB: " + error.message });
    }
};

// --- OBTENER LISTA DE ACTIVOS (CORREGIDO) ---
exports.getTriajesActivos = async (req, res) => {
    try {
        // 1. Buscamos los triajes
        const listaTriaje = await Triaje.findAll({
            where: {
                estado: { [Sequelize.Op.ne]: 'Alta' } 
            },
            include: [{
                model: Paciente,
                // CORRECCIÓN: Pedimos 'nombre_apellido' que SÍ existe en tu modelo
                attributes: ['cedula', 'nombre_apellido', 'edad'], 
                required: true // INNER JOIN
            }],
            order: [
                [Sequelize.literal(`CASE 
                    WHEN "Triaje".color = 'Rojo' THEN 1
                    WHEN "Triaje".color = 'Naranja' THEN 2
                    WHEN "Triaje".color = 'Amarillo' THEN 3
                    WHEN "Triaje".color = 'Verde' THEN 4
                    WHEN "Triaje".color = 'Azul' THEN 5
                    ELSE 6 
                END`), 'ASC'],
                ['createdAt', 'ASC'] 
            ]
        });

        // 2. Transformamos la respuesta (Asegúrate que esto esté DENTRO del try)
        const respuesta = listaTriaje.map(t => {
            const data = t.toJSON(); 
            const pacienteData = data.Paciente || data.paciente || {};

            // Usamos el campo correcto: nombre_apellido
            const nombreCompleto = pacienteData.nombre_apellido || 'Desconocido';
            
            return {
                id_triaje: data.id_triaje,
                cedula_paciente: data.cedula_paciente,
                color: data.color,
                ubicacion: data.ubicacion,
                estado: data.estado,
                motivo_ingreso: data.motivo_ingreso,
                signos_vitales: data.signos_vitales,
                createdAt: data.createdAt,
                estado: data.estado,
                
                // Mapeo correcto para el frontend
                nombre_completo: nombreCompleto,
                // Simulamos nombre y apellido separando por espacio (opcional)
                nombre: nombreCompleto.split(' ')[0], 
                apellido: nombreCompleto.split(' ').slice(1).join(' '),
                edad: pacienteData.edad || '?',
                residente_atendiendo: data.residente_atendiendo || null,
            };
        });

        // 3. Enviamos la respuesta
        res.status(200).send(respuesta);

    } catch (error) {
        console.error("Error getTriajesActivos:", error);
        res.status(500).send({ message: "Error al obtener lista: " + error.message });
    }
};

// Actualizar estado
exports.updateEstado = async (req, res) => {
    try {
        const { id } = req.params;
        const { estado } = req.body;

        const triaje = await Triaje.findByPk(id);
        if (!triaje) return res.status(404).send({ message: "Triaje no encontrado" });

        triaje.estado = estado;
        await triaje.save();

        res.status(200).send({ message: `Estado actualizado a ${estado}` });
    } catch (error) {
        res.status(500).send({ message: "Error: " + error.message });
    }
};

// Obtener por cédula
exports.getTriajeByCedula = async (req, res) => {
    try {
        const { cedula } = req.params;
        const triaje = await Triaje.findOne({ 
            where: { cedula_paciente: cedula },
            order: [['createdAt', 'DESC']]
        });

        if (!triaje) return res.status(404).send({ message: "Sin registros." });
        res.status(200).send(triaje);
    } catch (error) {
        res.status(500).send({ message: error.message });
    }
};

// --- ATENDER PACIENTE ---
exports.atenderTriaje = async (req, res) => {
    try {
        const { id } = req.params; // El ID del triaje (viene de la tarjeta)
        const { nombre_residente } = req.body; // El nombre del usuario logueado en la App

        const triaje = await Triaje.findByPk(id);

        if (!triaje) {
            return res.status(404).send({ message: "Triaje no encontrado" });
        }

        // Validamos que no esté ya en alta
        if (triaje.estado === 'Alta') {
            return res.status(400).send({ message: "El paciente ya fue dado de alta." });
        }

        // Actualizamos datos
        triaje.estado = 'Siendo Atendido';
        triaje.residente_atendiendo = nombre_residente;
        
        await triaje.save();

        res.status(200).send({ 
            message: "Paciente en atención.", 
            triaje: triaje 
        });

    } catch (error) {
        console.error("Error al atender:", error);
        res.status(500).send({ message: "Error al procesar: " + error.message });
    }
};

// --- ACTUALIZAR TRIAJE EXISTENTE (Nuevo) ---
exports.updateTriaje = async (req, res) => {
    try {
        const { id } = req.params;
        // Obtenemos los campos que queremos permitir actualizar
        const { color, ubicacion, signos_vitales, motivo_ingreso } = req.body;

        const triaje = await Triaje.findByPk(id);

        if (!triaje) {
            return res.status(404).send({ message: "Triaje no encontrado." });
        }

        // Actualizamos los campos si vienen en la petición
        if (color) triaje.color = color;
        if (ubicacion) triaje.ubicacion = ubicacion;
        if (signos_vitales) triaje.signos_vitales = signos_vitales;
        if (motivo_ingreso) triaje.motivo_ingreso = motivo_ingreso;

        await triaje.save();

        res.status(200).send({ 
            success: true,
            message: "Triaje actualizado correctamente.", 
            data: triaje 
        });
    } catch (error) {
        console.error("Error updateTriaje:", error);
        res.status(500).send({ 
            success: false, 
            message: "Error al actualizar triaje: " + error.message 
        });
    }
};