require('dotenv').config();

module.exports = {
    // Usamos la variable de entorno, y si no existe, usamos la clave temporal.
    // ASÍ GARANTIZAMOS QUE AMBOS LADOS USEN LO MISMO.
    secret: process.env.JWT_SECRET || "clave-secreta-temporal-tesis-2024"
};