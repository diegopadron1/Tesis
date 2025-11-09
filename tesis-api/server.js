// server.js (Modificado)
const express = require('express');
const cors = require('cors');
// Importa el objeto db completo (conexión, modelos y relaciones)
const db = require('./models');
const patientRoutes = require('./routes/patientRoutes');

require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;



// -----------------------------------------------------------------
// 1. Configuración de CORS (Permitir solicitudes del navegador)
// -----------------------------------------------------------------
const corsOptions = {
    // Permitir acceso desde CUALQUIER origen (Para desarrollo)
    // En producción, se recomienda especificar tu dominio/IP de la web
    origin: '*', 
};
app.use(cors(corsOptions));

app.use(express.json());
app.use('/api', patientRoutes);
// -----------------------------------------------------------------
// 1. Conectar y Sincronizar la base de datos
// -----------------------------------------------------------------
async function startServer() {
    // Prueba la conexión
    await db.connectDB();
    
    // **IMPORTANTE**: Sincroniza los modelos. 
    // Si la tabla no existe, la crea. Si usas { alter: true } modifica la tabla existente.
    // Usaremos force: false, para evitar borrar tus tablas existentes
    await db.sequelize.sync({ alter: true })
        .then(() => {
            console.log('✅ Base de datos sincronizada con los modelos.');
            // Aquí puedes ejecutar una función para crear el Rol y el Usuario Administrador inicial
            initialDataSetup(); 
        })
        .catch((err) => {
            console.error('❌ Error al sincronizar la base de datos:', err);
            process.exit(1);
        });
        
    // -----------------------------------------------------------------
    // 2. Definir una ruta de prueba (Endpoint)
    // -----------------------------------------------------------------
    app.get('/', (req, res) => {
      res.status(200).send({
        message: "API del Sistema de Emergencia Dr. Luis Razetti está funcionando.",
        status: "online"
      });
    });
    require('./routes/auth.routes')(app);
    require('./routes/user.routes')(app);
    // -----------------------------------------------------------------
    // 3. Iniciar el servidor
    // -----------------------------------------------------------------
    app.listen(PORT, '0.0.0.0', () => {
        console.log(`🚀 Servidor Express escuchando en http://localhost:${PORT}`);
    });
}

// Función para crear el Rol y el primer Administrador
const bcrypt = require('bcryptjs');

async function initialDataSetup() {
    try {
        // 1. Crear Roles (si no existen)
        const roles = ['Administrador', 'Residente', 'Enfermera', 'Farmacia', 'Especialista'];
        for (const nombre of roles) {
            await db.Rol.findOrCreate({
                where: { nombre_rol: nombre },
                defaults: { nombre_rol: nombre }
            });
        }
        console.log('✅ Roles base creados o verificados.');

        // 2. Crear Usuario Administrador (si no existe)
        const adminRol = await db.Rol.findOne({ where: { nombre_rol: 'Administrador' } });
        
        if (adminRol) {
            const adminCedula = 'V12345678'; // Cédula de ejemplo para el Admin
            const adminUser = await db.Usuario.findOne({ where: { cedula: adminCedula } });
            
            if (!adminUser) {
                const hashedPassword = bcrypt.hashSync('admin123', 10); // Contraseña inicial segura
                
                await db.Usuario.create({
                    cedula: adminCedula,
                    nombre: 'Admin',
                    apellido: 'Sistema',
                    email: 'admin@razetti.com',
                    password: hashedPassword,
                    id_rol: adminRol.id_rol
                });
                console.log(`✅ Usuario Administrador inicial creado con Cédula: ${adminCedula} y Contraseña: admin123`);
            }
        }
    } catch (error) {
        console.error('❌ Error en la configuración inicial:', error);
    }
}

// Inicia la aplicación
startServer();