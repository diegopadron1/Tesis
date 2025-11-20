// routes/user.routes.js (CORREGIDO)
const { verifyToken, isAdmin } = require("../middlewares/authJwt");
const controller = require("../controllers/user.controller");


module.exports = function(app) {
    // Rutas protegidas por el token
    // 1. Middleware de Headers
    app.use(function(req, res, next) {
        res.header(
            "Access-Control-Allow-Headers",
            "x-access-token, Origin, Content-Type, Accept"
        );
        next();
    }); // <--- EL CIERRE DEL app.use DEBE SER AQUÍ

    // 2. Rutas que usan el patrón app.get/app.post (Fuera del middleware anterior)
    
    app.get(
        "/api/roles",
        [verifyToken], // Solo requiere token válido
        controller.findAllRoles
    );

    // Endpoint de prueba que requiere:
    // ...
    app.get(
        "/api/test/admin",
        [verifyToken, isAdmin],
        controller.adminBoard
    );

    app.post(
        "/api/admin/users",
        [verifyToken, isAdmin],
        controller.createUser
    );

    app.get(
        "/api/admin/users",
        [verifyToken, isAdmin],
        controller.findAllUsers
    );

    app.put(
        "/api/admin/users/:cedula",
        [verifyToken, isAdmin],
        controller.updateUser
    );
};


