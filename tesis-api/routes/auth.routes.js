// routes/auth.routes.js
const controller = require("../controllers/auth.controller");

module.exports = function(app) {
    // Permite que cualquier origen (cliente móvil) acceda
    app.use(function(req, res, next) {
        res.header(
            "Access-Control-Allow-Headers",
            "x-access-token, Origin, Content-Type, Accept"
        );
        next();
    });

    // Endpoint principal de login
    app.post("/api/auth/signin", controller.signin);

    // --- NUEVAS RUTAS DE RECUPERACIÓN ---
    
    // 1. Solicitar código por correo
    // Body esperado: { "email": "usuario@correo.com" }
    app.post("/api/auth/forgot-password", controller.forgotPassword);

    // 2. Cambiar contraseña usando el código
    // Body esperado: { "token": "CODIGO_RECIBIDO", "newPassword": "NUEVA_CLAVE" }
    app.post("/api/auth/reset-password", controller.resetPassword);
};