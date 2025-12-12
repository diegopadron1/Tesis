const db = require('../models');
const MotivoConsulta = db.MotivoConsulta;
const Carpeta = db.Carpeta; // Necesitamos el modelo Carpeta
const { Op } = require("sequelize"); // Para comparar fechas

exports.createMotivoConsulta = async (req, res) => {
    console.log("Intentando crear Motivo de Consulta...");
    
    // 1. Validar la entrada
    const { cedula_paciente, motivo_consulta } = req.body;

    // Opcional: Si el frontend manda quién atiende, captúralo aquí
    const { id_usuario, atendido_por } = req.body; 

    if (!cedula_paciente || !motivo_consulta) {
        return res.status(400).send({
            message: 'Debe proporcionar la cédula del paciente y el motivo de la consulta.'
        });
    }

    try {
        // --- LÓGICA DE CARPETA AUTOMÁTICA ---
        
        // Definir rango de tiempo (HOY)
        const inicioDia = new Date();
        inicioDia.setHours(0, 0, 0, 0);
        const finDia = new Date();
        finDia.setHours(23, 59, 59, 999);

        // A. Buscar carpeta existente de hoy
        let carpeta = await Carpeta.findOne({
            where: {
                cedula_paciente: cedula_paciente,
                createdAt: {
                    [Op.gte]: inicioDia, 
                    [Op.lte]: finDia     
                }
            }
        });

        // B. Si no existe, crearla
        if (!carpeta) {
            console.log(`📂 Creando carpeta automática para ${cedula_paciente}...`);
            carpeta = await Carpeta.create({
                cedula_paciente: cedula_paciente,
                fecha_creacion: new Date(),
                estatus: 'ABIERTA',
                id_usuario: id_usuario || null,     // Opcional
                atendido_por: atendido_por || null  // Opcional
            });
        }

        // --- CREAR EL REGISTRO VINCULADO ---

        const nuevoMotivo = await MotivoConsulta.create({
            cedula_paciente: cedula_paciente,
            motivo_consulta: motivo_consulta,
            id_carpeta: carpeta.id_carpeta // <--- ¡LA PIEZA CLAVE!
        });

        // 3. Respuesta exitosa
        res.status(201).send({
            message: 'Motivo de consulta registrado exitosamente.',
            data: nuevoMotivo,
            id_carpeta: carpeta.id_carpeta // Devolvemos el ID por si el frontend lo necesita
        });

    } catch (error) {
        // 4. Manejo de errores
        console.error('Error al crear motivo de consulta:', error);
        res.status(500).send({
            message: error.message || 'Ocurrió un error interno al registrar el motivo de consulta.'
        });
    }
};

// Podrías añadir una función para obtener el historial:
// exports.getMotivosByPaciente = async (req, res) => { ... }