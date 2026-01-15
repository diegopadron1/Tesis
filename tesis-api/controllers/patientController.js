const { check, validationResult } = require('express-validator');
const db = require('../models'); 
const sequelize = db.sequelize; 
// Importamos los modelos directamente para usar .create()
const Paciente = db.Paciente;
const ContactoEmergencia = db.ContactoEmergencia;
const Carpeta = db.Carpeta;

/**
 * Función auxiliar para calcular la edad
 */
const calcularEdad = (fechaNacimiento) => {
    const hoy = new Date();
    const nacimiento = new Date(fechaNacimiento);
    let edad = hoy.getFullYear() - nacimiento.getFullYear();
    const mes = hoy.getMonth() - nacimiento.getMonth();
    
    if (mes < 0 || (mes === 0 && hoy.getDate() < nacimiento.getDate())) {
        edad--;
    }
    return edad;
};

/**
 * Middleware de validación
 */
exports.validatePatientRegistration = [
    check('paciente.cedula', 'La cédula es obligatoria.').isLength({ min: 5, max: 15 }).isNumeric(),
    check('paciente.nombre', 'El nombre es obligatorio.').notEmpty(),
    check('paciente.apellido', 'El apellido es obligatorio.').notEmpty(),
    check('paciente.sexo', 'El sexo es obligatorio y debe ser válido.').isIn(['Masculino', 'Femenino', 'Otro']),
    check('paciente.telefono', 'El teléfono es obligatorio.').isNumeric().isLength({ min: 10, max: 15 }),
    check('paciente.fecha_nacimiento', 'Fecha de nacimiento obligatoria.').isISO8601().toDate(),
    check('paciente.lugar_nacimiento', 'Lugar de nacimiento obligatorio.').notEmpty(),
    check('paciente.direccion_actual', 'Dirección obligatoria.').notEmpty(),
    check('contactoEmergencia.nombre', 'Nombre de contacto obligatorio.').notEmpty(),
    check('contactoEmergencia.apellido', 'Apellido de contacto obligatorio.').notEmpty(),
    check('contactoEmergencia.parentesco', 'Parentesco obligatorio.').notEmpty(),
    check('contactoEmergencia.telefono', 'Teléfono de contacto obligatorio.').isNumeric()
];

/**
 * Registro de Paciente + Contacto + Carpeta Inicial (Usando ORM)
 */
exports.registerPatient = async (req, res) => {
    // 1. Validación de Errores
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        const errorMessages = errors.array().map(err => err.msg);
        return res.status(400).json({ success: false, message: 'Errores de validación:', errors: errorMessages });
    }

    const { paciente, contactoEmergencia } = req.body;
    let transaction; 

    try {
        // Iniciamos la transacción
        transaction = await sequelize.transaction();
        
        // Preparar datos calculados
        const edadCalculada = calcularEdad(paciente.fecha_nacimiento);
        const nombreCompletoPaciente = `${paciente.nombre} ${paciente.apellido}`;
        const nombreCompletoContacto = `${contactoEmergencia.nombre} ${contactoEmergencia.apellido}`;

        // 2. Verificar existencia (Usando ORM es más limpio)
        const existingPatient = await Paciente.findOne({ 
            where: { cedula: paciente.cedula },
            transaction 
        });

        if (existingPatient) {
            await transaction.rollback();
            return res.status(409).json({ success: false, message: `El paciente con cédula ${paciente.cedula} ya está registrado.` });
        }

        // 3. Crear Paciente (Sequelize maneja los timestamps automáticamente)
        // Nota: Usamos las claves exactas que definiste en tu modelo o BD
        await Paciente.create({
            cedula: paciente.cedula,
            nombre_apellido: nombreCompletoPaciente,
            sexo: paciente.sexo, 
            edad: edadCalculada,
            telefono: paciente.telefono,
            fecha_nacimiento: paciente.fecha_nacimiento,
            lugar_nacimiento: paciente.lugar_nacimiento,
            direccion_actual: paciente.direccion_actual,
            Estado_civil: paciente.Estado_civil || paciente.estado_civil || paciente.estadoCivil,
            Religion: paciente.religion || paciente.Religion
        }, { transaction });
        
        // 4. Crear Contacto de Emergencia
        await ContactoEmergencia.create({
            cedula_paciente: paciente.cedula,
            nombre_apellido: nombreCompletoContacto,
            cedula_contacto: contactoEmergencia.cedula_contacto,
            parentesco: contactoEmergencia.parentesco,
            telefono: contactoEmergencia.telefono
        }, { transaction });

        // 5. Crear Carpeta Inicial (Automática)
        await Carpeta.create({
            cedula_paciente: paciente.cedula,
            fecha_creacion: new Date(),
            estatus: 'ABIERTA',
            // id_usuario: req.body.id_usuario // Opcional: si lo tienes disponible
        }, { transaction });

        // 6. Confirmar todo
        await transaction.commit();

        res.status(201).json({ 
            success: true, 
            message: 'Paciente registrado exitosamente (Carpeta #1 creada).', 
            cedula: paciente.cedula 
        });

    } catch (error) {
        if (transaction) await transaction.rollback();

        console.error('Error al registrar paciente:', error);
        
        const msg = error.name === 'SequelizeUniqueConstraintError' 
            ? 'Error: Ya existe un registro con esos datos únicos.' 
            : 'Error interno del servidor.';

        res.status(500).json({ success: false, message: msg, error: error.message });
    }
};