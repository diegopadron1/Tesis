const express = require('express');
const cors = require('cors');
const db = require('./models'); // Importa el objeto db configurado en models/index.js
const bcrypt = require('bcryptjs'); // Necesario para la contraseña del admin
require('dotenv').config();

// --- IMPORTACIÓN DE RUTAS ---
const patientRoutes = require('./routes/patientRoutes');
const motivoConsultaRoutes = require('./routes/motivoConsulta.routes');
const diagnosticoRoutes = require('./routes/diagnostico.routes');
const examenRoutes = require('./routes/examen.routes');
const antecedentesRoutes = require('./routes/antecedentes.routes');
const farmaciaRoutes = require('./routes/farmacia.routes');
const enfermeriaRoutes = require('./routes/enfermeria.routes');
const historiaRoutes = require('./routes/historia.routes');
// --- NUEVA RUTA DE TRIAJE ---
const triajeRoutes = require('./routes/triaje.routes');

const app = express();
const PORT = process.env.PORT || 3000;

// -----------------------------------------------------------------
// 1. Configuración de Middleware
// -----------------------------------------------------------------
const corsOptions = {
    origin: '*', 
};
app.use(cors(corsOptions));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// -----------------------------------------------------------------
// 2. Definición de Rutas (Endpoints)
// -----------------------------------------------------------------
app.get('/', (req, res) => {
    res.status(200).send({
        message: "API del Sistema de Emergencia Dr. Luis Razetti está funcionando.",
        status: "online"
    });
});

app.use('/api', patientRoutes);
app.use('/api', motivoConsultaRoutes);
app.use('/api', diagnosticoRoutes);
app.use('/api', examenRoutes);
app.use('/api', antecedentesRoutes);
app.use('/api/farmacia', farmaciaRoutes);
app.use('/api/enfermeria', enfermeriaRoutes);
app.use('/api/historia', historiaRoutes);
app.use('/api', require('./routes/reporte.routes'));
// Usamos la nueva ruta
app.use('/api', triajeRoutes); 

// Importamos rutas que funcionan con require(app)
require('./routes/auth.routes')(app);
require('./routes/user.routes')(app);

// -----------------------------------------------------------------
// 3. Inicio del Servidor y Base de Datos
// -----------------------------------------------------------------
async function startServer() {
    try {
        if (db.connectDB) {
            await db.connectDB();
            console.log('✅ Conexión establecida.');

            // --- CÓDIGO DE LIMPIEZA DE BASE DE DATOS ---
            try {
                console.log('🔧 Intentando corregir columna estado...');
                
                // 1. Eliminar el valor por defecto temporalmente para evitar el error de casting
                await db.sequelize.query('ALTER TABLE "Triaje" ALTER COLUMN "estado" DROP DEFAULT;');
                
                // 2. Forzar la columna a ser TEXTO (VARCHAR)
                await db.sequelize.query('ALTER TABLE "Triaje" ALTER COLUMN "estado" TYPE VARCHAR(255);');
                
                // 3. Volver a poner el valor por defecto pero como Texto simple
                await db.sequelize.query("ALTER TABLE \"Triaje\" ALTER COLUMN \"estado\" SET DEFAULT 'En Espera';");
                
                // 4. Borrar el tipo ENUM viejo si existe para que no estorbe
                await db.sequelize.query('DROP TYPE IF EXISTS "enum_Triaje_estado";');
                
                console.log('✅ Columna estado corregida a TEXTO.');
            } catch (err) {
                console.log('ℹ️ La corrección no fue necesaria o ya se aplicó: ' + err.message);
            }
            // -------------------------------------------

            // Sincronización normal
            await db.sequelize.sync({ alter: true });
            console.log('✅ Base de datos sincronizada.');

            await initialDataSetup();
        } else {
            console.error("❌ Error Crítico: No se encontró la función connectDB.");
        }

        app.listen(PORT, '0.0.0.0', () => {
            console.log(`🚀 Servidor Express escuchando en http://localhost:${PORT}`);
        });

    } catch (error) {
        console.error('❌ Error fatal al iniciar el servidor:', error);
        process.exit(1);
    }
}

// -----------------------------------------------------------------
// 4. Función de Datos Iniciales (Roles y Admin)
// -----------------------------------------------------------------
async function initialDataSetup() {
    try {
        const Rol = db.role; 
        const Usuario = db.user;

        if (!Rol || !Usuario) {
            console.error("⚠️ Advertencia: No se encontraron los modelos 'role' o 'user'. Saltando carga inicial.");
            return;
        }

        const roles = ['Administrador', 'Residente', 'Enfermera', 'Farmacia', 'Especialista'];
        
        for (const nombre of roles) {
            await Rol.findOrCreate({
                where: { nombre_rol: nombre },
                defaults: { nombre_rol: nombre }
            });
        }
        console.log('✅ Roles base verificados.');

        const adminRol = await Rol.findOne({ where: { nombre_rol: 'Administrador' } });
        
        if (adminRol) {
            const adminCedula = 'V12345678'; 
            const adminUser = await Usuario.findOne({ where: { cedula: adminCedula } });
            
            if (!adminUser) {
                const hashedPassword = bcrypt.hashSync('admin123', 10);
                
                await Usuario.create({
                    cedula: adminCedula,
                    nombre: 'Admin',
                    apellido: 'Sistema',
                    email: 'admin@razetti.com',
                    password: hashedPassword,
                    id_rol: adminRol.id_rol 
                });
                console.log(`✅ Usuario Administrador creado: ${adminCedula} / admin123`);
            }
        }

    } catch (error) {
        console.error('❌ Error en la carga de datos iniciales:', error.message);
    }
}

startServer();