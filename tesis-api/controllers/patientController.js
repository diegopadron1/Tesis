// controllers/patientController.js

const { check, validationResult } = require('express-validator');
const { sequelize } = require('../config/db.config'); // Importa sequelize
const { QueryTypes } = require('sequelize');

/**
 * Función auxiliar para calcular la edad a partir de la fecha de nacimiento (YYYY-MM-DD)
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
 * Middleware de validación de datos (Ajustado al esquema de la tesis)
 */
exports.validatePatientRegistration = [
    // --- Validación de Paciente ---
    check('paciente.cedula', 'La cédula es obligatoria.')
        .isLength({ min: 5, max: 15 }).withMessage('La cédula debe tener entre 5 y 15 caracteres.')
        .isNumeric().withMessage('La cédula debe ser un número válido.'),
    check('paciente.nombre', 'El nombre es obligatorio.').notEmpty(),
    check('paciente.apellido', 'El apellido es obligatorio.').notEmpty(),
    check('paciente.telefono', 'El teléfono del paciente es obligatorio.')
        .isNumeric().isLength({ min: 10, max: 15 }),
    check('paciente.fecha_nacimiento', 'La fecha de nacimiento es obligatoria (YYYY-MM-DD).')
        .isISO8601().toDate(),
    check('paciente.lugar_nacimiento', 'El lugar de nacimiento es obligatorio.').notEmpty(),
    check('paciente.direccion_actual', 'La dirección actual es obligatoria.').notEmpty(),

    // --- Validación de Contacto de Emergencia ---
    check('contactoEmergencia.nombre', 'El nombre del contacto es obligatorio.').notEmpty(),
    check('contactoEmergencia.apellido', 'El apellido del contacto es obligatorio.').notEmpty(),
    check('contactoEmergencia.cedula_contacto', 'La cédula del contacto debe ser válida.').optional().isLength(),
    check('contactoEmergencia.parentesco', 'El parentesco es obligatorio.').notEmpty(), 
];


/**
 * Registra un nuevo paciente y su contacto de emergencia en una transacción.
 */
exports.registerPatient = async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        const errorMessages = errors.array().map(err => err.msg);
        return res.status(400).json({ success: false, message: 'Errores de validación:', errors: errorMessages });
    }

    const { paciente, contactoEmergencia } = req.body;
    let transaction; 

    try {
        transaction = await sequelize.transaction();
        
        // 1. Procesamiento de datos
        const edadCalculada = calcularEdad(paciente.fecha_nacimiento);
        const nombreCompletoPaciente = `${paciente.nombre} ${paciente.apellido}`;
        const nombreCompletoContacto = `${contactoEmergencia.nombre} ${contactoEmergencia.apellido}`;

        // 2. Verificar si el Paciente ya existe (USANDO COMILLAS DOBLES)
        const existingPatient = await sequelize.query(
            'SELECT cedula FROM "Paciente" WHERE cedula = :cedula',
            {
                replacements: { cedula: paciente.cedula },
                type: QueryTypes.SELECT,
                transaction,
            }
        );

        if (existingPatient.length > 0) {
            await transaction.rollback();
            return res.status(409).json({ success: false, message: `El paciente con cédula ${paciente.cedula} ya está registrado.` });
        }

        // 3. Insertar Paciente (Usando comillas dobles para tablas y columnas capitalizadas)
        const patientQuery = `
            INSERT INTO "Paciente" (
                cedula, nombre_apellido, edad, telefono, fecha_nacimiento, 
                lugar_nacimiento, direccion_actual, "Estado_civil", "Religion"
            )
            VALUES (
                :cedula, :nombre_apellido, :edad, :telefono, :fecha_nacimiento, 
                :lugar_nacimiento, :direccion_actual, :estado_civil, :religion
            )
            RETURNING cedula;
        `;

        await sequelize.query(patientQuery, {
            replacements: { 
                cedula: paciente.cedula,
                nombre_apellido: nombreCompletoPaciente,
                edad: edadCalculada,
                telefono: paciente.telefono,
                fecha_nacimiento: paciente.fecha_nacimiento,
                lugar_nacimiento: paciente.lugar_nacimiento || null,
                direccion_actual: paciente.direccion_actual || null,
                estado_civil: paciente.Estado_civil || null,
                religion: paciente.Religion || null         
            },
            type: QueryTypes.INSERT,
            transaction,
        });
        
        // 4. Insertar Contacto de Emergencia
        const contactQuery = `
            INSERT INTO "ContactoEmergencia" (
                cedula_paciente, nombre_apellido, cedula_contacto, parentesco
            )
            VALUES (
                :cedula_paciente, :nombre_apellido, :cedula_contacto, :parentesco
            )
            RETURNING id_contacto;
        `;
        
        await sequelize.query(contactQuery, {
            replacements: {
                cedula_paciente: paciente.cedula,
                nombre_apellido: nombreCompletoContacto,
                cedula_contacto: contactoEmergencia.cedula_contacto || null,
                parentesco: contactoEmergencia.parentesco
            },
            type: QueryTypes.INSERT,
            transaction,
        });

        // 5. Commit
        await transaction.commit();

        res.status(201).json({ 
            success: true, 
            message: 'Paciente y contacto de emergencia registrados con éxito.', 
            cedula: paciente.cedula 
        });

    } catch (error) {
        if (transaction) await transaction.rollback();

        console.error('Error al registrar el paciente y contacto:', error);
        
        const errorMessage = error.name === 'SequelizeUniqueConstraintError' 
            ? 'Error de duplicidad de datos.' 
            : 'Error interno del servidor al procesar el registro (Revisar logs para restricciones de DB).';

        res.status(500).json({ success: false, message: errorMessage });
    }
};