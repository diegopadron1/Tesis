const db = require('../models');
const Triaje = db.Triaje;
const Paciente = db.Paciente;
const Carpeta = db.Carpeta; 
const OrdenesMedicas = db.OrdenesMedicas; // <--- NUEVA IMPORTACIÓN
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

        const inicioDia = new Date(); inicioDia.setHours(0, 0, 0, 0);
        const finDia = new Date(); finDia.setHours(23, 59, 59, 999);

        const ultimaCarpeta = await Carpeta.findOne({
            where: {
                cedula_paciente: cedula_paciente,
                createdAt: { [Op.gte]: inicioDia, [Op.lte]: finDia }
            },
            order: [['createdAt', 'DESC']]
        });

        let carpeta;
        if (!ultimaCarpeta || ultimaCarpeta.estatus === 'Alta' || ultimaCarpeta.estatus === 'Fallecido') {
            carpeta = await Carpeta.create({
                cedula_paciente: cedula_paciente,
                fecha_creacion: new Date(),
                estatus: 'ABIERTA',
                id_usuario: id_usuario || null,
                atendido_por: atendido_por || null
            });
        } else {
            carpeta = ultimaCarpeta;
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

// ... (getTriajesActivos y getPacientesReferidos se mantienen igual)

exports.getTriajesActivos = async (req, res) => {
    try {
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

// ... (getTriajeByCedula, atenderTriaje y updateTriaje se mantienen igual)
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