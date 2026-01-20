const db = require('../models');
const Triaje = db.Triaje;
const Paciente = db.Paciente;
const Carpeta = db.Carpeta; 
const OrdenesMedicas = db.OrdenesMedicas; 
const Medicamento = db.Medicamento;
const SolicitudMedicamento = db.SolicitudMedicamento; 
const Sequelize = db.Sequelize;
const { Op } = require("sequelize"); 

// 1. Registrar un nuevo Triaje
exports.createTriaje = async (req, res) => {
    try {
        const { cedula_paciente, color, ubicacion, motivo_ingreso, signos_vitales } = req.body;
        const { id_usuario, atendido_por } = req.body; 

        const pacienteExistente = await Paciente.findOne({ where: { cedula: cedula_paciente } });
        if (!pacienteExistente) {
            return res.status(404).send({ message: "Paciente no encontrado. Regístrelo primero." });
        }

        // --- CAMBIO IMPORTANTE: LOGICA DE CARPETA ACTIVA ---
        // Buscamos la última carpeta que NO esté cerrada (Alta, Fallecido, Traslado)
        // Esto permite encontrar pacientes ingresados ayer u otros días.
        
        const ultimaCarpeta = await Carpeta.findOne({
            where: {
                cedula_paciente: cedula_paciente,
                estatus: { 
                    [Op.notIn]: ['Alta', 'Fallecido', 'Traslado'] 
                }
            },
            order: [['createdAt', 'DESC']]
        });

        let carpeta;
        
        if (ultimaCarpeta) {
            // Si ya tiene una carpeta abierta (de ayer o hoy), la reutilizamos
            console.log(`📂 Paciente con ingreso activo. Usando carpeta existente ID: ${ultimaCarpeta.id_carpeta}`);
            carpeta = ultimaCarpeta;
        } else {
            // Si no tiene carpeta activa (es un nuevo ingreso), creamos una nueva
            console.log("📂 Nuevo ingreso detectado. Creando carpeta clínica...");
            carpeta = await Carpeta.create({
                cedula_paciente: cedula_paciente,
                fecha_creacion: new Date(),
                estatus: 'ABIERTA',
                id_usuario: id_usuario || null,
                atendido_por: atendido_por || null
            });
        }

        const nuevoTriaje = await Triaje.create({
            cedula_paciente,
            color,
            ubicacion,
            motivo_ingreso,
            signos_vitales,
            estado: 'En Espera',
            id_carpeta: carpeta.id_carpeta 
        });

        res.status(201).send({ message: "Triaje registrado.", data: nuevoTriaje, id_carpeta: carpeta.id_carpeta });
    } catch (error) {
        res.status(500).send({ message: "Error DB: " + error.message });
    }
};

// 2. Obtener Triajes Activos (CORREGIDO Y OPTIMIZADO)
exports.getTriajesActivos = async (req, res) => {
    try {
        // PASO 1: Obtener los triajes activos
        const listaTriaje = await Triaje.findAll({
            where: {
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

        // PASO 2: Recopilar los IDs de las carpetas
        const carpetaIds = listaTriaje
            .map(t => t.id_carpeta)
            .filter(id => id !== null && id !== undefined);

        // PASO 3: Buscar las órdenes médicas PENDIENTES con sus MEDICAMENTOS y SOLICITUDES
        let mapaOrdenes = {};
        
        if (carpetaIds.length > 0) {
            const ordenesEncontradas = await OrdenesMedicas.findAll({
                where: {
                    id_carpeta: { [Op.in]: carpetaIds },
                    estatus: 'PENDIENTE'
                },
                attributes: ['id_orden', 'id_carpeta', 'indicaciones_inmediatas', 'tratamientos_sugeridos', 'requerimiento_medicamentos'], // Agregado requerimiento_medicamentos
                include: [
                    {
                        model: Medicamento,
                        as: 'medicamento',  // Alias correcto según models/index.js
                        attributes: ['nombre', 'concentracion']
                    },
                    {
                        model: SolicitudMedicamento,
                        as: 'solicitudes', // Alias correcto según models/index.js
                        required: false,
                        attributes: ['estatus'] 
                    }
                ],
                order: [['createdAt', 'DESC']]
            });

            // Llenamos el mapa con la orden más reciente
            ordenesEncontradas.forEach(orden => {
                if (!mapaOrdenes[orden.id_carpeta]) {
                    mapaOrdenes[orden.id_carpeta] = orden;
                }
            });
        }

        // PASO 4: Combinar los datos
        const respuesta = listaTriaje.map(t => {
            const data = t.toJSON(); 
            const pacienteData = data.Paciente || data.paciente || {};
            const nombreCompleto = pacienteData.nombre_apellido || 'Desconocido';
            
            // Buscamos si existe orden para este triaje
            const ordenData = mapaOrdenes[data.id_carpeta];
            const medData = ordenData ? ordenData.medicamento : null;
            
            // LÓGICA DE ESTADO FARMACIA
            let estadoFarmacia = null;
            if (ordenData && ordenData.solicitudes && ordenData.solicitudes.length > 0) {
                // Si existe solicitud, tomamos el estado de la primera (la más reciente si ordenamos bien)
                estadoFarmacia = ordenData.solicitudes[0].estatus || 'PENDIENTE';
            }

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
                
                // DATOS MÉDICOS INYECTADOS
                tiene_orden: !!ordenData,
                estado_farmacia: estadoFarmacia, // Nuevo dato para el frontend
                // Enviar el texto completo de medicamentos para la vista de enfermería
                indicaciones_medicamentos: ordenData ? ordenData.requerimiento_medicamentos : "Ninguna registrada",
                nombre_medicamento: medData ? medData.nombre : null,
                concentracion: medData ? medData.concentracion : null,
                indicaciones_inmediatas: ordenData ? ordenData.indicaciones_inmediatas : "Ninguna registrada",
                tratamientos_sugeridos: ordenData ? ordenData.tratamientos_sugeridos : "Pendiente"
            };
        });

        res.status(200).send(respuesta);

    } catch (error) {
        console.error("Error en getTriajesActivos:", error);
        res.status(500).send({ message: "Error al obtener lista: " + error.message });
    }
};

exports.getPacientesReferidos = async (req, res) => {
    try {
        const listaTrasladados = await Triaje.findAll({
            where: { estado: 'Traslado' },
            include: [{ model: Paciente, attributes: ['cedula', 'nombre_apellido', 'edad'], required: true }],
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
        res.status(500).send({ message: "Error al obtener traslados: " + error.message });
    }
};

// --- ACTUALIZAR ESTADO GENÉRICO (CON CANCELACIÓN AUTOMÁTICA) ---
exports.updateEstado = async (req, res) => {
    try {
        const { id } = req.params;
        const { estado } = req.body; 

        const triaje = await Triaje.findByPk(id);
        if (!triaje) return res.status(404).send({ message: "Triaje no encontrado" });

        // 1. Actualizar el estado del Triaje
        triaje.estado = estado;
        await triaje.save();

        // 2. MANEJO DE LA CARPETA Y ÓRDENES
        if (triaje.id_carpeta) {
            if (['Alta', 'Fallecido'].includes(estado)) {
                console.log(`🔒 Cerrando visita y cancelando órdenes para Carpeta ID ${triaje.id_carpeta}`);
                
                // ACTUALIZACIÓN MASIVA: Cancelar órdenes pendientes de esta visita
                await OrdenesMedicas.update(
                    { estatus: 'CANCELADA' },
                    { 
                        where: { 
                            id_carpeta: triaje.id_carpeta, 
                            estatus: 'PENDIENTE' 
                        } 
                    }
                );

                // Cerrar la carpeta
                await Carpeta.update(
                    { estatus: estado },
                    { where: { id_carpeta: triaje.id_carpeta } }
                );
            }
        }

        res.status(200).send({ message: `Estado actualizado a ${estado}. Órdenes pendientes (si existían) han sido canceladas.` });
    } catch (error) {
        res.status(500).send({ message: "Error: " + error.message });
    }
};

// --- FINALIZAR ATENCIÓN ESPECIALISTA (CON CANCELACIÓN AUTOMÁTICA) ---
exports.finalizarEspecialista = async (req, res) => {
    try {
        const { id } = req.params;
        const { motivo } = req.body; 

        if (!['Alta', 'Fallecido'].includes(motivo)) {
            return res.status(400).send({ message: "Motivo no válido." });
        }

        const triaje = await Triaje.findByPk(id);
        if (!triaje) return res.status(404).send({ message: "Triaje no encontrado" });

        triaje.estado = motivo;
        await triaje.save();

        if (triaje.id_carpeta) {
            console.log(`🔒 Especialista cerrando visita y limpiando órdenes para Carpeta ID ${triaje.id_carpeta}`);
            
            // Cancelar órdenes pendientes antes de cerrar
            await OrdenesMedicas.update(
                { estatus: 'CANCELADA' },
                { 
                    where: { 
                        id_carpeta: triaje.id_carpeta, 
                        estatus: 'PENDIENTE' 
                    } 
                }
            );

            await Carpeta.update(
                { estatus: motivo },
                { where: { id_carpeta: triaje.id_carpeta } }
            );
        }

        res.status(200).send({ success: true, message: `Paciente finalizado. Órdenes no administradas fueron canceladas.` });
    } catch (error) {
        res.status(500).send({ message: "Error al finalizar: " + error.message });
    }
};

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

exports.atenderTriaje = async (req, res) => {
    try {
        const { id } = req.params; 
        const { nombre_residente, nueva_ubicacion } = req.body; 
        const triaje = await Triaje.findByPk(id);
        if (!triaje) return res.status(404).send({ message: "Triaje no encontrado" });
        if (['Alta', 'Fallecido'].includes(triaje.estado)) return res.status(400).send({ message: "El paciente ya fue cerrado." });

        triaje.estado = 'Siendo Atendido';
        triaje.residente_atendiendo = nombre_residente;
        if (nueva_ubicacion) triaje.ubicacion = nueva_ubicacion;
        await triaje.save();

        res.status(200).send({ message: "Paciente en atención.", triaje: triaje });
    } catch (error) {
        res.status(500).send({ message: "Error al procesar: " + error.message });
    }
};

exports.updateTriaje = async (req, res) => {
    try {
        const { id } = req.params;
        const { color, ubicacion, signos_vitales, motivo_ingreso } = req.body;
        const triaje = await Triaje.findByPk(id);
        if (!triaje) return res.status(404).send({ message: "Triaje no encontrado." });

        if (color) triaje.color = color;
        if (ubicacion) triaje.ubicacion = ubicacion;
        if (signos_vitales) triaje.signos_vitales = signos_vitales;
        if (motivo_ingreso) triaje.motivo_ingreso = motivo_ingreso;

        await triaje.save();
        res.status(200).send({ success: true, message: "Triaje actualizado.", data: triaje });
    } catch (error) {
        res.status(500).send({ success: false, message: "Error: " + error.message });
    }
};