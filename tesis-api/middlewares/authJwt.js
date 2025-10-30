// middlewares/authJwt.js
const jwt = require("jsonwebtoken");
const JWT_SECRET = process.env.JWT_SECRET; // Usamos la clave del .env

// 1. Middleware para verificar el Token JWT
const verifyToken = (req, res, next) => {
    // 1.1 Obtener el token del header
    let token = req.headers["x-access-token"];

    if (!token) {
        return res.status(403).send({
            message: "Se requiere un token de acceso!"
        });
    }

    // 1.2 Verificar la validez del token
    jwt.verify(token, JWT_SECRET, (err, decoded) => {
        if (err) {
            return res.status(401).send({
                message: "Acceso no autorizado! Token inválido o expirado."
            });
        }
        
        // 1.3 Si es válido, guardamos la cédula y el rol del usuario en la solicitud (req)
        req.cedula = decoded.cedula;
        req.rol = decoded.rol; 
        next(); // Permite que la solicitud continúe al siguiente controlador
    });
};

// 2. Middleware para verificar si el usuario es Administrador
const isAdmin = (req, res, next) => {
    // Asumimos que el rol ya fue decodificado y guardado en req.rol por verifyToken
    if (req.rol === "Administrador") {
        next(); // Es Administrador, puede continuar
        return;
    }

    res.status(403).send({
        message: "Se requiere Rol de Administrador para esta acción."
    });
};

// 3. Middleware para verificar si es Farmacia
const isFarmacia = (req, res, next) => {
    if (req.rol === "Farmacia") {
        next();
        return;
    }

    res.status(403).send({
        message: "Se requiere Rol de Farmacia para esta acción."
    });
};

// 4. Middleware para verificar si es Médico (Residente o Especialista)
const isMedico = (req, res, next) => {
    if (req.rol === "Residente" || req.rol === "Especialista") {
        next();
        return;
    }

    res.status(403).send({
        message: "Se requiere Rol de Médico (Residente/Especialista) para esta acción."
    });
};


const authJwt = {
    verifyToken,
    isAdmin,
    isFarmacia,
    isMedico
};

module.exports = authJwt;