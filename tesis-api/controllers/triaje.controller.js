const db = require('../models');
const Triaje = db.Triaje;
const Paciente = db.Paciente;
const Carpeta = db.Carpeta; 
const Sequelize = db.Sequelize;
const { Op } = require("sequelize"); 

// 1. Registrar un nuevo Triaje (CON LÓGICA MULTI-VISITA)
exports.createTriaje = async (req, res) => {
    try {
        const { cedula_paciente, color, ubicacion, motivo_ingreso, signos_vitales } = req.body;
        const { id_usuario, atendido_por } = req.body; 

        // 1. Validar Paciente
        const pacienteExistente = await Paciente.findOne({ where: { cedula: cedula_paciente } });
        if (!pacienteExistente) {
            return res.status(404).send({ message: "Paciente no encontrado. Regístrelo primero." });
        }

        // 2. LÓGICA DE CARPETA INTELIGENTE
        const inicioDia = new Date(); inicioDia.setHours(0, 0, 0, 0);
        const finDia = new Date(); finDia.setHours(23, 59, 59, 999);

        // Buscar la ÚLTIMA carpeta de hoy
        const ultimaCarpeta = await Carpeta.findOne({
            where: {
                cedula_paciente: cedula_paciente,
                createdAt: { [Op.gte]: inicioDia, [Op.lte]: finDia }
            },
            order: [['createdAt', 'DESC']]
        });

        let carpeta;

        // Si NO existe hoy O si la última ya fue dada de Alta -> Creamos nueva
        if (!ultimaCarpeta || ultimaCarpeta.estatus === 'Alta' || ultimaCarpeta.estatus === 'Fallecido') {
            console.log(`📂 Creando carpeta automática (Triaje - Nueva visita) para ${cedula_paciente}...`);
            
            carpeta = await Carpeta.create({
                cedula_paciente: cedula_paciente,
                fecha_creacion: new Date(),
                estatus: 'ABIERTA',
                id_usuario: id_usuario || null,
                atendido_por: atendido_por || null
            });
        } else {
            // Si está ABIERTA o en TRASLADO, usamos la existente
            carpeta = ultimaCarpeta;
        }

        // 3. Crear Triaje Vinculado
        const nuevoTriaje = await Triaje.create({
            cedula_paciente,
            color,
            ubicacion,
            motivo_ingreso,
            signos_vitales,
            estado: 'En Espera',
            id_carpeta: carpeta.id_carpeta 
        });

        res.status(201).send({ 
            message: "Triaje registrado.", 
            data: nuevoTriaje,
            id_carpeta: carpeta.id_carpeta
        });

    } catch (error) {
        console.error("Error createTriaje:", error);
        res.status(500).send({ message: "Error DB: " + error.message });
    }
};

// --- OBTENER LISTA DE ACTIVOS (Triaje General) ---
exports.getTriajesActivos = async (req, res) => {
    try {
        const listaTriaje = await Triaje.findAll({
            where: {
                // EXCLUIMOS: Alta, Fallecido y TRASLADO (Traslado va al especialista)
                estado: { [Sequelize.Op.notIn]: ['Alta', 'Fallecido', 'Traslado'] } 
            },
            include: [{
                model: Paciente,
                attributes: ['cedula', 'nombre_apellido', 'edad'], 
                required: true 
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

        const respuesta = listaTriaje.map(t => {
            const data = t.toJSON(); 
            const pacienteData = data.Paciente || data.paciente || {};
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
                nombre_completo: nombreCompleto,
                nombre: nombreCompleto.split(' ')[0], 
                apellido: nombreCompleto.split(' ').slice(1).join(' '),
                edad: pacienteData.edad || '?',
                residente_atendiendo: data.residente_atendiendo || null,
            };
        });

        res.status(200).send(respuesta);

    } catch (error) {
        console.error("Error getTriajesActivos:", error);
        res.status(500).send({ message: "Error al obtener lista: " + error.message });
    }
};

// --- OBTENER LISTA DE TRASLADADOS (PARA ESPECIALISTAS) ---
exports.getPacientesReferidos = async (req, res) => {
    try {
        const listaTrasladados = await Triaje.findAll({
            where: {
                estado: 'Traslado' 
            },
            include: [{
                model: Paciente,
                attributes: ['cedula', 'nombre_apellido', 'edad'], 
                required: true 
            }],
            order: [['updatedAt', 'DESC']] 
        });

        const respuesta = listaTrasladados.map(t => {
            const data = t.toJSON(); 
            const pacienteData = data.Paciente || data.paciente || {};
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
                updatedAt: data.updatedAt,
                nombre_completo: nombreCompleto,
                nombre: nombreCompleto.split(' ')[0], 
                apellido: nombreCompleto.split(' ').slice(1).join(' '),
                edad: pacienteData.edad || '?',
                residente_atendiendo: data.residente_atendiendo || 'N/A',
            };
        });

        res.status(200).send(respuesta);

    } catch (error) {
        console.error("Error getPacientesReferidos:", error);
        res.status(500).send({ message: "Error al obtener traslados: " + error.message });
    }
};

// --- ACTUALIZAR ESTADO GENÉRICO ---
exports.updateEstado = async (req, res) => {
    try {
        const { id } = req.params;
        const { estado } = req.body; 

        const triaje = await Triaje.findByPk(id);
        if (!triaje) return res.status(404).send({ message: "Triaje no encontrado" });

        // 1. Actualizar el estado del Triaje
        triaje.estado = estado;
        await triaje.save();

        // 2. MANEJO DE LA CARPETA
        if (triaje.id_carpeta) {
            if (['Alta', 'Fallecido'].includes(estado)) {
                console.log(`🔒 Cerrando carpeta ID ${triaje.id_carpeta} por estatus: ${estado}`);
                await Carpeta.update(
                    { estatus: estado },
                    { where: { id_carpeta: triaje.id_carpeta } }
                );
            }
        }

        res.status(200).send({ message: `Estado actualizado a ${estado}.` });
    } catch (error) {
        console.error("Error updateEstado:", error);
        res.status(500).send({ message: "Error: " + error.message });
    }
};

// --- [NUEVO] FINALIZAR ATENCIÓN (ESPECIALISTA) ---
// Esta función maneja específicamente el Alta o Fallecimiento desde el panel de especialista
exports.finalizarEspecialista = async (req, res) => {
    try {
        const { id } = req.params;
        const { motivo, observaciones } = req.body; // 'Alta' o 'Fallecido'

        // Validación básica
        if (!['Alta', 'Fallecido'].includes(motivo)) {
            return res.status(400).send({ message: "Motivo no válido. Use 'Alta' o 'Fallecido'." });
        }

        const triaje = await Triaje.findByPk(id);
        if (!triaje) return res.status(404).send({ message: "Triaje no encontrado" });

        // 1. Actualizar Triaje
        triaje.estado = motivo;
        // Si tienes campo de observaciones en la BD, descomenta la linea de abajo:
        // triaje.observaciones = observaciones; 
        await triaje.save();

        // 2. Cerrar Carpeta (Obligatorio al finalizar)
        if (triaje.id_carpeta) {
            console.log(`🔒 Especialista cerrando carpeta ID ${triaje.id_carpeta} por: ${motivo}`);
            await Carpeta.update(
                { estatus: motivo }, // La carpeta queda como 'Alta' o 'Fallecido'
                { where: { id_carpeta: triaje.id_carpeta } }
            );
        }

        res.status(200).send({ 
            success: true,
            message: `Paciente finalizado correctamente (${motivo}).` 
        });

    } catch (error) {
        console.error("Error finalizarEspecialista:", error);
        res.status(500).send({ message: "Error al finalizar: " + error.message });
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

// --- ATENDER PACIENTE (Con opción de cambio de zona) ---
exports.atenderTriaje = async (req, res) => {
    try {
        const { id } = req.params; 
        const { nombre_residente, nueva_ubicacion } = req.body; 

        const triaje = await Triaje.findByPk(id);

        if (!triaje) {
            return res.status(404).send({ message: "Triaje no encontrado" });
        }

        if (['Alta', 'Fallecido'].includes(triaje.estado)) {
            return res.status(400).send({ message: "El paciente ya fue cerrado." });
        }

        // Actualizamos datos
        triaje.estado = 'Siendo Atendido';
        triaje.residente_atendiendo = nombre_residente;
        
        if (nueva_ubicacion) {
            triaje.ubicacion = nueva_ubicacion;
        }
        
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

// --- ACTUALIZAR TRIAJE EXISTENTE (Edición de datos) ---
exports.updateTriaje = async (req, res) => {
    try {
        const { id } = req.params;
        const { color, ubicacion, signos_vitales, motivo_ingreso } = req.body;

        const triaje = await Triaje.findByPk(id);

        if (!triaje) {
            return res.status(404).send({ message: "Triaje no encontrado." });
        }

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