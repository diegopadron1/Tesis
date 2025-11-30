const jwt = require("jsonwebtoken");
const config = require("../config/auth.config.js"); // <--- LA SOLUCIÓN

// 1. Verificar Token
const verifyToken = (req, res, next) => {
    let token = req.headers["x-access-token"];

    if (!token) {
        return res.status(403).send({ message: "Se requiere un token de acceso!" });
    }

    jwt.verify(token, config.secret, (err, decoded) => {
        if (err) {
            return res.status(401).send({ message: "Acceso no autorizado! Token inválido." });
        }
        req.cedula = decoded.cedula;
        req.rol = decoded.rol;
        next();
    });
};

// 2. Admin
const isAdmin = (req, res, next) => {
    if (req.rol === "Administrador") {
        next();
        return;
    }
    res.status(403).send({ message: "Se requiere Rol de Administrador." });
};

// 3. Farmacia
const isFarmacia = (req, res, next) => {
    if (req.rol === "Farmacia") {
        next();
        return;
    }
    res.status(403).send({ message: "Se requiere Rol de Farmacia." });
};

// 4. Resident/Especialista
const isResident = (req, res, next) => {
    if (req.rol === "Residente" || req.rol === "Especialista") {
        next();
        return;
    }
    res.status(403).send({ message: "Se requiere Rol Médico." });
};

const isAdminOrResident = (req, res, next) => {
    if (req.rol === "Administrador" || req.rol === "Residente") {
        next();
        return;
    }
    res.status(403).send({ message: "Se requiere Admin o Residente." });
};

const authJwt = {
    verifyToken,
    isAdmin,
    isFarmacia,
    isResident,
    isAdminOrResident
};

module.exports = authJwt;