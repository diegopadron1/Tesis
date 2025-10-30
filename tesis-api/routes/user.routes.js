// routes/user.routes.js
const { verifyToken, isAdmin } = require("../middlewares/authJwt");
const controller = require("../controllers/user.controller");


module.exports = function(app) {
    // Rutas protegidas por el token
    app.use(function(req, res, next) {
        res.header(
            "Access-Control-Allow-Headers",
            "x-access-token, Origin, Content-Type, Accept"
        );
        next();
    app.get(
        "/api/roles",
        [verifyToken], // Solo requiere token válido
        controller.findAllRoles
    );
    });

    // Endpoint de prueba que requiere:
    // 1. Tener un token válido (verifyToken)
    // 2. Tener el rol de Administrador (isAdmin)
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


