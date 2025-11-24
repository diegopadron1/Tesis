const express = require('express');
const cors = require('cors');
const db = require('./models'); // Importa el objeto db configurado en models/index.js
const bcrypt = require('bcryptjs'); // Necesario para la contraseña del admin
require('dotenv').config();

// --- IMPORTACIÓN DE RUTAS ---
// (Respetando tus rutas originales)
const patientRoutes = require('./routes/patientRoutes');
const motivoConsultaRoutes = require('./routes/motivoConsulta.routes');
const diagnosticoRoutes = require('./routes/diagnostico.routes');
const examenRoutes = require('./routes/examen.routes');
const antecedentesRoutes = require('./routes/antecedentes.routes');
const farmaciaRoutes = require('./routes/farmacia.routes');
// Rutas de autenticación y usuario (Si no están en los archivos de arriba)
// require('./routes/auth.routes')(app); -> Lo moveremos abajo para integrarlo correctamente

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

// Importamos rutas que funcionan con require(app)
require('./routes/auth.routes')(app);
require('./routes/user.routes')(app);

// -----------------------------------------------------------------
// 3. Inicio del Servidor y Base de Datos
// -----------------------------------------------------------------
async function startServer() {
    try {
        // A. Conectar a la Base de Datos
        // Usamos la función robusta que creamos en models/index.js
        if (db.connectDB) {
            await db.connectDB();
            // Nota: db.connectDB() ya hace el sync(), así que no es necesario repetirlo aquí
            // a menos que quieras forzar { alter: true } explícitamente.
            
            console.log('✅ Base de datos lista.');
            
            // B. Configuración Inicial de Datos (Roles y Admin)
            await initialDataSetup();
        } else {
            console.error("❌ Error Crítico: No se encontró la función connectDB en los modelos.");
        }

        // C. Levantar el servidor
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
        // CORRECCIÓN CLAVE: Usamos db.role y db.user (minúsculas)
        // porque así se definieron en models/index.js
        const Rol = db.role; 
        const Usuario = db.user;

        if (!Rol || !Usuario) {
            console.error("⚠️ Advertencia: No se encontraron los modelos 'role' o 'user'. Saltando carga inicial.");
            return;
        }

        // 1. Crear Roles
        // Nota: Asegúrate que los nombres coincidan EXACTAMENTE con lo que espera tu frontend/auth
        const roles = ['Administrador', 'Residente', 'Enfermera', 'Farmacia', 'Especialista'];
        
        for (const nombre of roles) {
            await Rol.findOrCreate({
                where: { nombre_rol: nombre },
                defaults: { nombre_rol: nombre }
            });
        }
        console.log('✅ Roles base verificados.');

        // 2. Crear Usuario Administrador
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
                    id_rol: adminRol.id_rol // Usamos id_rol según tu modelo Rol.js
                });
                console.log(`✅ Usuario Administrador creado: ${adminCedula} / admin123`);
            }
        }

    } catch (error) {
        console.error('❌ Error en la carga de datos iniciales:', error.message);
    }
}

// Inicia la aplicación
startServer();