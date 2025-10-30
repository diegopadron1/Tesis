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
};