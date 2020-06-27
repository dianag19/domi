const jwt = require('jsonwebtoken');
require('../config/config');

const verificaToken = function (req, res, next) {

    let token = req.get('Authorization');
    jwt.verify(token, process.env.SEED, (err, decoded) => {
        if (err) {
            return res.status(401).json({
                ok: false,
                message: 'Token incorrecto'
            });
        }

        //req.usuario = decoded.usuario;

        next();

    });

};

const verificaUserRole = function (req, res, next) {

    let usuario = req.usuario;

    if (usuario.role = 'User') {
        next();
    } else {

        return res.json({
            ok: false,
            err: {
                message: 'No es Usuario'
            }
        });

    }
};

module.exports = {
    verificaToken,
    verificaUserRole
};