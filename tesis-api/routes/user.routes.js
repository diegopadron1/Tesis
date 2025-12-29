// routes/user.routes.js (CORREGIDO Y ACTUALIZADO)
const { verifyToken, isAdmin } = require("../middlewares/authJwt");
const controller = require("../controllers/user.controller");

module.exports = function(app) {
    // 1. Middleware de Headers
    app.use(function(req, res, next) {
        res.header(
            "Access-Control-Allow-Headers",
            "x-access-token, Origin, Content-Type, Accept"
        );
        next();
    });

    // 2. Rutas de Roles y Test
    app.get(
        "/api/roles",
        [verifyToken],
        controller.findAllRoles
    );

    app.get(
        "/api/test/admin",
        [verifyToken, isAdmin],
        controller.adminBoard
    );

    // 3. RUTAS DE USUARIOS (ORDEN IMPORTANTE)
    
    // El buscador debe ir PRIMERO
    app.get(
        "/api/admin/users/search",
        [verifyToken, isAdmin],
        controller.searchUsersByCedula
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