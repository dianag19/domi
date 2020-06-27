const Pool = require('pg').Pool;
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const Joi = require('joi');
const connectionData = require('../config/config').connectionData;
const pool = new Pool(connectionData);
let carrerasPorTomar = new Array(); //Guarda los taxistas que fueron encontrados para una determinada carrera con la siguiente info
                                    // [numero de celular del usuario, id del taxista encontrado, placa del taxi, coordenadas donde recogera al usuario,
                                    // coordenadas donde terminara la carrera, la distancia a la que se encuntran] las coordenadas se ven asi '(longitud,latitud)'

let usuariosPorAceptar = new Array();//Guarda los usuarios que faltan por aceptar una carrera que un taxista a confirmado que va a tomar

let usuariosPorCalificar = new Array();//Guarda a los usuarios que tienen una carrrera pendiente por calificar

//Tener en cuenta
//El schema son los campos que se necesitan con sus determinadas restricciones
//Las descripciones de lo que hace cada funcion estan en la parte de mas abajo

// ALL QUERIES, HERE: 

const createUser = (request, response) => {
    const body = request.body;

    const schema = {
        cel: Joi.string().min(10).max(13).required().regex(/^[0-9]+$/),
        name: Joi.string().min(1).max(50).required().regex(/^[^±!@£$%^&*_+§¡€#¢¶•ªº«\\/<>?:;|=.,]{1,50}$/),
        ap: Joi.string().min(1).max(50).required().regex(/^[^±!@£$%^&*_+§¡€#¢¶•ªº«\\/<>?:;|=.,]{1,50}$/),
        tc: Joi.string().required().creditCard(),
        pass: Joi.string().min(8).required()
    };

    const {error} = Joi.validate(request.body, schema);

    if (error) {
        response.status(400).send(error.details[0].message);
    } else {
        pool.query('INSERT INTO usuario (num_cel_u, nombre_u, apellido_u, tarjeta_credito, password) VALUES ($1, $2, $3, $4, $5)',
            [body.cel, body.name, body.ap, bcrypt.hashSync(body.tc, 10), bcrypt.hashSync(body.pass, 10)], (error, results) => {
                if (error) {
                    return response.status(400).json({
                        ok: false,
                        err: error
                    });
                }

                response.status(201).json({
                    ok: true,
                    message: `Usuario: ${body.name} ${body.ap} con celular: ${body.cel} creado con exito`,
                    usuario: {
                        name: body.name,
                        apellido: body.ap,
                        num_cel: body.cel
                    }
                });
            })
    }
};

const createDirFav = (request, response) => {
    const body = request.body;
    const schema = {
        cel: Joi.string().min(10).max(13).required().regex(/^[0-9]+$/),
        nombre: Joi.string().min(1).max(250).required(),
        coords: Joi.string().required().regex(/^[(]{1}-{0,1}(((1[0-7][0-9]|[1-9][0-9]|[0-9])[.][0-9]{1,30})|180[.]0{1,30})[,]{1}[" "]{0,1}[-]{0,1}((([1-8][0-9]|[0-9])[.][0-9]{1,30})|90[.]0{1,30})[)]{1}$/)
    };

    const {error} = Joi.validate(request.body, schema);

    if (error) {
        return response.status(400).send(error.details[0].message);
    }

    function insertarDirFav() {
        pool.query('INSERT INTO dir_fav (num_cel_u, nombre_dir, coords_gps_u) VALUES ($1, $2, $3)',
            [body.cel, body.nombre, body.coords], (error, results) => {
                if (error) {
                    return response.status(400).json({
                        ok: false,
                        err: error
                    });
                }

                response.status(201).json({
                    ok: true,
                    message: `Direccion guardada con exito`,
                    usuario: {
                        nombre: body.nombre,
                        coords: body.coords,
                        usuario: body.cel
                    }
                });
            })
    }

    pool.query('SELECT * FROM dir_fav WHERE num_cel_u = $1',
        [body.cel], (error, results) => {
            if (error) {
                return response.status(400).json({
                    ok: false,
                    err: error
                });
            }

            if (!results.rows[0]) {
                return insertarDirFav();
            }

            let cascaron = body.coords.replace(/[0-9]|[.]/g, '').split(',');
            let numerosCoords = body.coords.replace(/[^0-9.,]/g, '').split(',');
            let resuBody = cascaron[0] + numerosCoords[0].split('.')[0] + '.' + numerosCoords[0].split('.')[1].substring(0, 3) + ',' +
                numerosCoords[1].split('.')[0] + '.' + numerosCoords[1].split('.')[1].substring(0, 3) + cascaron[1];

            for (let i = 0; i < results.rows.length; i++) {
                let resu = '(' + results.rows[i].coords_gps_u.x.toString().split('.')[0] + '.' + results.rows[i].coords_gps_u.x.toString().split('.')[1].substring(0, 3) + ',' +
                    results.rows[i].coords_gps_u.y.toString().split('.')[0] + '.' + results.rows[i].coords_gps_u.y.toString().split('.')[1].substring(0, 3) + ')';

                if (results.rows[i].nombre_dir === body.nombre) {
                    return response.status(400).json({
                        ok: false,
                        message: 'El nombre que intenta poner ya existe'
                    });
                } else if (resu === resuBody) {
                    return response.status(400).json({
                        ok: false,
                        message: 'Ya tiene otra direccion guardada en el mismo lugar'
                    });
                } else if (i === results.rows.length - 1) {
                    insertarDirFav();
                }
            }
        });
};

const createTaxista = (request, response) => {
    const body = request.body;

    const schema = {
        id_taxista: Joi.string().max(20).required().regex(/^[0-9]+$/),
        nombre_t: Joi.string().min(1).max(50).required().regex(/^[^±!@£$%^&*_+§¡€#¢¶•ªº«\\/<>?:;|=.,]{1,50}$/),
        apellido_t: Joi.string().min(1).max(50).required().regex(/^[^±!@£$%^&*_+§¡€#¢¶•ªº«\\/<>?:;|=.,]{1,50}$/),
        num_cel_t: Joi.string().min(10).max(13).required().regex(/^[0-9]+$/),
        password_t: Joi.string().min(8).required(),
        num_cuenta: Joi.string().max(24).required().regex(/^[0-9]+$/)
    };

    const {error} = Joi.validate(request.body, schema);

    if (error) {
        response.status(400).send(error.details[0].message);
    } else {
        pool.query('INSERT INTO taxista (id_taxista, nombre_t, apellido_t, num_cel_t, password_t, num_cuenta) VALUES ($1, $2, $3, $4, $5, $6)',
            [body.id_taxista, body.nombre_t, body.apellido_t, body.num_cel_t, bcrypt.hashSync(body.password_t, 10),
                bcrypt.hashSync(body.num_cuenta, 10)], (error, results) => {

                if (error) {
                    return response.status(400).json({
                        ok: false,
                        err: error
                    });
                }
                response.status(201).json({
                    ok: true,
                    message: `taxista: ${body.nombre_t} ${body.apellido_t} con id: ${body.id_taxista} creado con exito`,
                    taxista: {
                        nombre: body.nombre_t,
                        apellido: body.apellido_t,
                        id: body.id_taxista
                    }
                });
            });
    }
};

const updateUser = (request, response) => {

    const body = request.body;

    const schema = {
        cel: Joi.string().min(10).max(13).required().regex(/^[0-9]+$/),
        nombre: Joi.string().min(1).max(50).required().regex(/^[^±!@£$%^&*_+§¡€#¢¶•ªº«\\/<>?:;|=.,]{1,50}$/),
        apellido: Joi.string().min(1).max(50).required().regex(/^[^±!@£$%^&*_+§¡€#¢¶•ªº«\\/<>?:;|=.,]{1,50}$/)
    };

    const {error} = Joi.validate(request.body, schema);

    if (error) {
        return response.status(400).send(error.details[0].message);
    }

    pool.query('UPDATE usuario SET nombre_u = $2, apellido_u = $3 WHERE num_cel_u = $1',
        [body.cel, body.nombre, body.apellido], (error) => {
            if (error) {
                return response.status(400).json({
                    ok: false,
                    err: error
                });
            }

            response.status(200).json({
                ok: true,
                message: `Actualizado con exito`,
                usuario: {
                    nombre: body.nombre,
                    apellido: body.apellido,
                    usuario: body.cel
                }
            });
        })
};

const updateTaxista = (request, response) => {

    const body = request.body;

    const schema = {
        id_taxista: Joi.string().max(20).required().regex(/^[0-9]+$/),
        nombre: Joi.string().min(1).max(50).required().regex(/^[^±!@£$%^&*_+§¡€#¢¶•ªº«\\/<>?:;|=.,]{1,50}$/),
        apellido: Joi.string().min(1).max(50).required().regex(/^[^±!@£$%^&*_+§¡€#¢¶•ªº«\\/<>?:;|=.,]{1,50}$/)
    };

    const {error} = Joi.validate(request.body, schema);

    if (error) {
        return response.status(400).send(error.details[0].message);
    }

    pool.query('UPDATE taxista SET nombre_t = $2, apellido_t = $3 WHERE id_taxista = $1',
        [body.id_taxista, body.nombre, body.apellido], (error) => {
            if (error) {
                return response.status(400).json({
                    ok: false,
                    err: error
                });
            }

            response.status(200).json({
                ok: true,
                message: `Actualizado con exito`,
                taxista: {
                    nombre: body.nombre,
                    apellido: body.apellido,
                    usuario: body.id_taxista
                }
            });
        })
};

const updateDirFav = (request, response) => {
    const body = request.body;
    const schema = {
        cel: Joi.string().min(10).max(13).required().regex(/^[0-9]+$/),
        nombre: Joi.string().min(1).max(250).required()
    };

    const {error} = Joi.validate(request.body, schema);

    if (error) {
        return response.status(400).send(error.details[0].message);
    }

    pool.query('SELECT * FROM dir_fav WHERE num_cel_u = $1',
        [body.cel], (error, results) => {
            if (error) {
                return response.status(400).json({
                    ok: false,
                    err: error
                });
            }

            for (let i = 0; i < results.rows.length; i++) {
                if (results.rows[i].nombre_dir === body.name) {
                    return response.status(400).json({
                        ok: false,
                        message: 'El nombre por el que intenta cambiar ya existe'
                    });
                } else if (i === results.rows.length) {
                    pool.query('UPDATE dir_fav SET nombre_dir = $2 WHERE num_cel_u = $1 AND nombre_dir = $2',
                        [body.cel, body.nombre], (error, results) => {
                            if (error) {
                                return response.status(400).json({
                                    ok: false,
                                    err: error
                                });
                            }

                            response.status(200).json({
                                ok: true,
                                message: `Direccion actualizada con exito`,
                                usuario: {
                                    nombre: body.nombre,
                                    usuario: body.cel
                                }
                            });
                        })
                }
            }
        })
};

const deleteUser = (request, response) => {
    let body = request.body;

    const schema = {
        num: Joi.string().min(10).max(13).required().regex(/^[0-9]+$/),
        pass: Joi.string().min(8).required()
    };

    const {error} = Joi.validate(request.body, schema);

    if (error) {
        return response.status(400).send(error.details[0].message);
    }

    pool.query('SELECT password, num_cel_u , nombre_u , apellido_u FROM usuario WHERE num_cel_u = $1', [body.num], (error, results) => {
        if (error) {
            return response.status(404).json({
                ok: false,
                error
            });
        }

        if (!results.rows[0]) {
            return response.status(400).json({
                ok: false,
                mensaje: 'Error'
            });
        }

        if (!bcrypt.compareSync(body.pass, results.rows[0].password)) {
            return response.status(400).json({
                ok: false,
                mensaje: 'Contraseña incorrecta',
            });
        } else {
            pool.query('DELETE FROM usuario WHERE num_cel_u = $1',
                [body.num], (error, results) => {
                    if (error) {
                        return response.status(400).json({
                            ok: false,
                            err: error
                        });
                    }

                    response.status(200).json({
                        ok: true,
                        message: `Usuario borrado con exito`,
                        usuario: {
                            usuario: body.cel
                        }
                    });
                })
        }
    })
};

const deleteDirFav = (request, response) => {

    const body = request.body;
    const schema = {
        num: Joi.string().min(10).max(13).required().regex(/^[0-9]+$/),
        nombre: Joi.string().min(1).max(250).required()
    };

    const {error} = Joi.validate(request.body, schema);

    if (error) {
        return response.status(400).send(error.details[0].message);
    }

    pool.query('DELETE FROM dir_fav WHERE num_cel_u = $1 AND nombre_dir',
        [body.num, body.nombre], (error, results) => {
            if (error) {
                return response.status(404).json({
                    ok: false,
                    err: error
                });
            }

            response.status(200).json({
                ok: true,
                message: `Direccion borrada con exito`
            });
        })
};

const loginUser = (request, response) => {
    let body = request.body;
    const schema = {
        num: Joi.string().min(10).max(13).required().regex(/^[0-9]+$/),
        pass: Joi.string().min(8).required()
    };

    const {error} = Joi.validate(request.body, schema);

    if (error) {
        return response.status(400).send(error.details[0].message);
    }

    pool.query('SELECT password, num_cel_u , nombre_u , apellido_u FROM usuario WHERE num_cel_u = $1', [body.num], (error, results) => {
        if (error) {
            return response.status(404).json({
                ok: false,
                error
            });
        }

        if (!results.rows[0]) {
            return response.status(400).json({
                ok: false,
                mensaje: 'Usuario o contraseña incorrectos'
            });
        }


        if (!bcrypt.compareSync(body.pass, results.rows[0].password)) {
            return response.status(400).json({
                ok: false,
                mensaje: 'Usuario o contraseña incorrectos',
            });
        }

        let usuario = {
            num_cel_u: results.rows[0].num_cel_u,
            nombre: results.rows[0].nombre_u,
            apellido: results.rows[0].apellido_u,
            role: 'User'
        };

        let token = jwt.sign({usuario}, process.env.SEED, {expiresIn: 14400}); // 4 horas

        response.status(200).json({
            ok: true,
            token,
            usuario
        });

    });

};

const loginTaxista = (request, response) => {
    let body = request.body;

    const schema = {
        id_taxista: Joi.string().max(20).required().regex(/^[0-9]+$/),
        pass: Joi.string().min(8).required()
    };

    const {error} = Joi.validate(request.body, schema);

    if (error) {
        return response.status(400).send(error.details[0].message);
    }

    pool.query('SELECT * FROM taxista WHERE id_taxista = $1', [body.id_taxista], (error, results) => {
        if (error) {
            console.log('ete error');
            return response.status(404).json({
                ok: false,
                error
            });
        }

        if (!results.rows[0]) {
            console.log('Usuario');
            return response.status(400).json({
                ok: false,
                mensaje: 'Usuario o contraseña incorrectos'
            });
        }


        if (!bcrypt.compareSync(body.pass, results.rows[0].password_t)) {
            console.log('Contrase~na');
            return response.status(400).json({
                ok: false,
                mensaje: 'Usuario o contraseña incorrectos',
            });
        }

        let taxista = {
            numeroCelular: results.rows[0].num_cel_t,
            nombre: results.rows[0].nombre_t,
            apellido: results.rows[0].apellido_t,
            idTaxista: results.rows[0].id_taxista,
            role: 'Taxista'
        };

        let token = jwt.sign({taxista}, process.env.SEED, {expiresIn: 14400}); // 4 horas

        return response.status(200).json({
            ok: true,
            token,
            taxista
        });
    });
};

const getDirections = (request, response) => {
    pool.query('SELECT * FROM dir_fav WHERE num_cel_u = $1', [request.params.id], (error, results) => {
        if (error) {
            return response.status(400).json({
                ok: false,
                err: error
            });
        }
        response.status(200).json(results.rows);
    });
};


const getUserById = (request, response) => {
    pool.query('SELECT * FROM perfiles_usuarios WHERE numero_de_celular = $1', [request.params.id], (error, results) => {
        if (error) {
            return response.status(400).json({
                ok: false,
                err: error
            });
        }
        response.status(200).json(results.rows);
    });
};

const getDriverById = (request, response) => {
    pool.query('SELECT * FROM perfiles_taxistas WHERE numero_de_identificacion = $1', [request.params.id], (error, results) => {
        if (error) {
            return response.status(400).json({
                ok: false,
                err: error
            });
        }
        response.status(200).json(results.rows);
    });
};

const revisarEstadoUsuario = (request, response) => {
    const params = request.params;

    const schema = {
        num: Joi.string().min(10).max(13).required().regex(/^[0-9]+$/)
    };

    const {error} = Joi.validate(request.params, schema);

    if (error) {
        return response.status(400).send(error.details[0].message);
    }

    for (let i = 0; i < usuariosPorCalificar.length; i++) {
        if (params.num === usuariosPorCalificar[i][0]) {
            return response.status(200).json({
                ok: true,
                estado: `calificando`
            })
        }
    }

    for (let i = 0; i < carrerasPorTomar.length; i++) {
        if (params.num === carrerasPorTomar[i][0]) {
            return response.status(200).json({
                ok: true,
                estado: `solicitando`
            })
        }
    }

    pool.query('SELECT * FROM carreras_en_curso WHERE num_cel_u = $1', [params.num], (error, results) => {
        if (error) {
            return response.status(404).json({
                ok: false,
                err: error
            });
        }

        if (results.rows[0]) {
            pool.query('SELECT * FROM usuario_a_taxista($1, $2)',
                [results.rows[0].id_taxista, results.rows[0].placa], (error, results) => {
                    if (error) {
                        return response.status(404).json({
                            ok: false,
                            err: error
                        });
                    }

                    let vistaDeTaxista = {
                        nombreCompleto: results.rows[0].nombre_completo,
                        numeroCelTaxista: results.rows[0].numero_de_celular,
                        placa: results.rows[0].placa,
                        marcaModelo: results.rows[0].marca_y_modelo,
                        numeroDeViajes: results.rows[0].numero_de_viajes,
                        puntaje: results.rows[0].puntaje
                    };

                    return response.status(200).json({
                        ok: true,
                        estado: `carrera`,
                        vistaDeTaxista
                    })
                });
        } else {
            return response.status(200).json({
                ok: false,
                estado: `ninguno`
            })
        }

    });
};

const revisarEstadoTaxista = (request, response) => {
    const params = request.params;

    const schema = {
        id_taxista: Joi.string().max(20).required().regex(/^[0-9]+$/)
    };

    const {error} = Joi.validate(request.params, schema);

    if (error) {
        return response.status(400).send(error.details[0].message);
    }

    pool.query('SELECT * FROM taxistas_en_servicio WHERE id_taxista = $1',
        [params.id_taxista], (error, results) => {
            if (error) {
                return response.status(404).json({
                    ok: false,
                    err: error
                });
            }

            if (!results.rows[0]) {
                return response.status(200).json({
                    ok: false,
                    estado: `ninguno`
                })
            }

            if (results.rows[0].estado) {
                return response.status(200).json({
                    ok: false,
                    estado: `buscando`
                })
            } else {
                pool.query('SELECT * FROM carreras_en_curso WHERE id_taxista = $1',
                    [params.id_taxista], (error, results) => {
                        if (error) {
                            return response.status(404).json({
                                ok: false,
                                err: error
                            });
                        }

                        let num = results.rows[0].num_cel_u;
                        let coordsILongitud = results.rows[0].coords_inicial.x;
                        let coordsILatitud = results.rows[0].coords_inicial.y;
                        let coordsFLongitud = results.rows[0].coords_final.x;
                        let coordsFLatitud = results.rows[0].coords_final.y;

                        pool.query('SELECT * FROM taxista_a_usuario($1)',
                            [num], (error, results) => {
                                if (error) {
                                    return response.status(404).json({
                                        ok: false,
                                        err: error
                                    });
                                }

                                let vistaDeUsuario = {
                                    nombreCompleto: results.rows[0].nombre_completo,
                                    numeroCelUsuario: results.rows[0].numero_de_celular,
                                    numeroDeViajes: results.rows[0].numero_de_viajes,
                                    ubicacionLat: coordsILatitud,
                                    ubicacionLong: coordsILongitud,
                                    destinoLat: coordsFLatitud,
                                    destinoLong: coordsFLongitud
                                };

                                console.log(vistaDeUsuario);
                                return response.status(200).json({
                                    ok: true,
                                    estado: `carrera`,
                                    vistaDeUsuario
                                })
                            })
                    })
            }

        });
};

const pedirCarrera = (request, response) => {
    console.log('pedirCarrera');
    const body = request.body;
    const schema = {
        num: Joi.string().min(10).max(13).required().regex(/^[0-9]+$/),
        coordsI: Joi.string().required().regex(/^[(]{1}-{0,1}(((1[0-7][0-9]|[1-9][0-9]|[0-9])[.][0-9]{1,30})|180[.]0{1,30})[,]{1}[" "]{0,1}[-]{0,1}((([1-8][0-9]|[0-9])[.][0-9]{1,30})|90[.]0{1,30})[)]{1}$/),
        coordsF: Joi.string().required().regex(/^[(]{1}-{0,1}(((1[0-7][0-9]|[1-9][0-9]|[0-9])[.][0-9]{1,30})|180[.]0{1,30})[,]{1}[" "]{0,1}[-]{0,1}((([1-8][0-9]|[0-9])[.][0-9]{1,30})|90[.]0{1,30})[)]{1}$/)
    };

    const {error} = Joi.validate(request.body, schema);

    if (error) {
        return response.status(400).send(error.details[0].message);
    }

    for (let i = 0; i < carrerasPorTomar.length; i++) {
        if (body.num === carrerasPorTomar[i][0]) {
            return response.status(404).json({
                ok: false,
                message: 'Usted ya hizo una solicitud'
            });
        }
    }


    function buscarTaxi(rango, limite) {
        pool.query('SELECT * FROM closest($1, $2, $3)', [body.coordsI, body.num, rango], (error, results) => {
            if (error) {
                return response.status(404).json({
                    ok: false,
                    err: error,
                    message: 'No hay taxis disponibles en este momento'
                });
            }

            if (!results.rows[0] && rango > limite) {
                return response.status(404).json({
                    ok: false,
                    message: 'No hay taxistas disponibles en su zona, busque mas tarde'
                });
            } else if (!results.rows[0]) {
                buscarTaxi((rango + 1.0), limite);
            } else {
                if (results.rows[0].id_taxista === 'error') {
                    return response.status(400).json({
                        ok: false,
                        message: 'Usted se encuentra en una carrera ahora no puede buscar'
                    });
                }

                response.status(200).json({
                    ok: true,
                    message: `Busqueda con exito, esperando confirmacion del taxista`,
                    busqueda: {
                        celular: body.num,
                    }
                });

                console.log('El taxi esta a ' + rango + ' KM');

                for (let i = 0; i < results.rows.length; i++) {
                    let meter = [body.num, results.rows[i].id_taxista, results.rows[i].placa, body.coordsI, body.coordsF, results.rows[i].distancia];
                    carrerasPorTomar.push(meter);
                }
            }
        });
    }

    pool.query('SELECT existe_usuario($1)', [body.num], (error, results) => {
        if (error) {
            return response.status(404).json({
                ok: false,
                err: error
            });
        }

        if (results.rows[0].existe_usuario) {
            buscarTaxi(1.0, 5.0);
        } else {
            return response.status(404).json({
                ok: false,
                err: error,
                message: 'Dicho usuario no existe'
            });
        }
    })
};

const buscarServicio = (request, response) => {
    console.log('buscarServicio');
    const body = request.body;

    const schema = {
        id_taxista: Joi.string().max(20).required().regex(/^[0-9]+$/)
    };

    const {error} = Joi.validate(request.body, schema);

    if (error) {
        return response.status(400).send(error.details[0].message);
    }

    let usuario_busqueda; //usuario al que el taxista le acepto la carrera
    let placaTaxista;
    let coordsILongitud;
    let coordsILatitud;
    let coordsFLongitud;
    let coordsFLatitud;
    let coordsI, coordsF;

    function existe(x) {
        for (let i = 0; i < carrerasPorTomar.length; i++) {
            if (x === carrerasPorTomar[i][1]) {
                usuario_busqueda = carrerasPorTomar[i][0];
                placaTaxista = carrerasPorTomar[i][2];
                coordsI = carrerasPorTomar[i][3];
                coordsF = carrerasPorTomar[i][4];
                coordsILongitud = carrerasPorTomar[i][3].split(',')[0].replace(/[(]/g, '');
                coordsILatitud = carrerasPorTomar[i][3].split(',')[1].replace(/[)]/g, '');
                coordsFLongitud = carrerasPorTomar[i][4].split(',')[0].replace(/[(]/g, '');
                coordsFLatitud = carrerasPorTomar[i][4].split(',')[1].replace(/[)]/g, '');
                return true;
            }
        }
        return false;
    }

    if (existe(body.id_taxista)) {
        pool.query('SELECT * FROM taxista_a_usuario($1)',
            [usuario_busqueda], (error, results) => {
                if (error) {
                    return response.status(404).json({
                        ok: false,
                        err: error
                    });
                }

                let vistaDeUsuario = {
                    nombreCompleto: results.rows[0].nombre_completo,
                    numeroCelUsuario: results.rows[0].numero_de_celular,
                    numeroDeViajes: results.rows[0].numero_de_viajes,
                    ubicacionLat: coordsILatitud,
                    ubicacionLong: coordsILongitud,
                    destinoLat: coordsFLatitud,
                    destinoLong: coordsFLongitud
                };

                response.status(200).json({
                    ok: true,
                    message: `Carrera encontrada!`,
                    numUsuario: usuario_busqueda,
                    vistaDeUsuario
                });

                usuariosPorAceptar.push([usuario_busqueda, body.id_taxista, placaTaxista, coordsI, coordsF]);
                console.log(usuariosPorAceptar);
            });

    } else {
        response.status(404).json({
            ok: false,
            message: 'Su servicio no ha sido solicitado'
        });
    }
};

const confirmarServicio = (request, response) => {
    console.log('buscarServicio');
    const body = request.body;

    const schema = {
        id_taxista: Joi.string().max(20).required().regex(/^[0-9]+$/)
    };

    const {error} = Joi.validate(request.body, schema);

    if (error) {
        return response.status(400).send(error.details[0].message);
    }

    let usuario_busqueda;

    function existe(x) {
        for (let i = 0; i < carrerasPorTomar.length; i++) {
            if (x === carrerasPorTomar[i][1]) {
                usuario_busqueda = carrerasPorTomar[i][0];
                return true;
            }
        }
        return false;
    }

    function borrar(x) {
        for (let i = 0; i < carrerasPorTomar.length; i++) {
            if (x === carrerasPorTomar[i][0]) { //borra todos los taxistas que no alcanzaron a aceptar del usuario carrerasPorTomar
                i -= 1;
                carrerasPorTomar.splice(i, 1);
            } else if (x === body.id_taxista) { //borra todas las apariciones del taxista que acepto la carrera de carrerasPorTomar
                i -= 1;
                carrerasPorTomar.splice(i, 1);
            }
        }
    }

    if (existe(body.id_taxista)) {

        for (let i = 0; i < usuariosPorAceptar.length; i++) {
            if (usuariosPorAceptar[i][0] === usuario_busqueda) {
                borrar(usuario_busqueda);
            }
        }

        return response.status(200).json({
            ok: true,
            message: `Carrera confirmada`
        });

    } else {
        response.status(404).json({
            ok: false,
            message: 'Su servicio no ha sido solicitado'
        });
    }
};

const notificarCarreraAceptada = (request, response) => {
    console.log('notificarCarreraAceptada');

    const body = request.body;
    const schema = {
        num: Joi.string().min(10).max(13).required().regex(/^[0-9]+$/)
    };

    const {error} = Joi.validate(request.body, schema);

    if (error) {
        return response.status(400).send(error.details[0].message);
    }

    let taxista, placa, coordsI, coordsF;

    function existe(x) {
        for (let i = 0; i < usuariosPorAceptar.length; i++) {
            if (x === usuariosPorAceptar[i][0]) {
                taxista = usuariosPorAceptar[i][1];
                placa = usuariosPorAceptar[i][2];
                coordsI = usuariosPorAceptar[i][3];
                coordsF = usuariosPorAceptar[i][4];

                usuariosPorAceptar.splice(i, 1);
                return true;
            }
        }
        return false;
    }

    if (existe(body.num)) {
        pool.query('SELECT * FROM comenzar_carrera($1, $2, $3, $4, $5)',
            [body.num, taxista, placa, coordsI, coordsF], (error, results) => {
                if (error) {
                    return response.status(400).json({
                        ok: false,
                        err: error
                    });
                }

                if (!results.rows[0].logrado) {
                    return response.status(400).json({
                        ok: false,
                        message: 'No se pudo comenzar la carrera, el taxista o usuario se encuentran en una carrera'
                    });
                }

                pool.query('SELECT * FROM usuario_a_taxista($1, $2)',
                    [taxista, placa], (error, results) => {
                        if (error) {
                            return response.status(404).json({
                                ok: false,
                                err: error
                            });
                        }

                        let vistaDeTaxista = {
                            nombreCompleto: results.rows[0].nombre_completo,
                            numeroCelTaxista: results.rows[0].numero_de_celular,
                            placa: results.rows[0].placa,
                            marcaModelo: results.rows[0].marca_y_modelo,
                            numeroDeViajes: results.rows[0].numero_de_viajes,
                            puntaje: results.rows[0].puntaje
                        };

                        response.status(200).json({
                            ok: true,
                            vistaDeTaxista,
                            message: 'La Carrera ha comenzado',
                        });
                    });

            });
    } else {
        response.status(404).json({
            ok: false,
            message: 'Su solicitud no ha sido aceptada'
        });
    }
};

const terminarCarrera = (request, response) => {
    console.log('terminarCarrera');
    //Sucede cuando el taxista le da al boton de terminar carrera
    const body = request.body;

    const schema = {
        id_taxista: Joi.string().max(20).required().regex(/^[0-9]+$/),
        coordsF: Joi.string().required().regex(/^[(]{1}-{0,1}(((1[0-7][0-9]|[1-9][0-9]|[0-9])[.][0-9]{1,15})|180[.]0{1,15})[,]{1}[" "]{0,1}[-]{0,1}((([1-8][0-9]|[0-9])[.][0-9]{1,15})|90[.]0{1,15})[)]{1}$/)
    };

    const {error} = Joi.validate(request.body, schema);

    if (error) {
        return response.status(400).send(error.details[0].message);
    }

    console.log(body.coordsF);

    pool.query('SELECT num_cel_u, placa FROM  carreras_en_curso WHERE id_taxista = $1',
        [body.id_taxista], (error, results) => {

            if (error) {
                return response.status(400).json({
                    ok: false,
                    err: error
                });
            }

            if (!results.rows[0]) {
                return response.status(400).json({
                    ok: false,
                    mensaje: 'No tiene carreras en curso'
                });
            }

            let num = results.rows[0].num_cel_u;
            let placa = results.rows[0].placa;

            pool.query('SELECT * from terminar_carrera($1, $2, $3, $4)',
                [num, body.id_taxista, placa, body.coordsF], (error, results) => {

                    if (error) {
                        return response.status(404).json({
                            ok: false,
                            err: error
                        });
                    }

                    usuariosPorCalificar.push([num, body.id_taxista, results.rows[0].costo]);

                    response.status(200).json({
                        ok: true,
                        costo: (results.rows[0].costo * 0.6),
                        message: 'La Carrera ha terminado',
                    });
                });

        });
};

const notificarCarreraTerminada = (request, response) => {
    console.log('notificarCarreraTerminada');
    //Sucede cuando el taxista le da al boton de terminar carrera (notifica al usuario que la carrera termino)
    const body = request.body;

    const schema = {
        num: Joi.string().min(10).max(13).required().regex(/^[0-9]+$/)
    };

    const {error} = Joi.validate(request.body, schema);

    if (error) {
        return response.status(400).send(error.details[0].message);
    }

    for (let i = 0; i < usuariosPorCalificar.length; i++) {
        if (usuariosPorCalificar[i][0] === body.num) {
            response.status(200).json({
                ok: true,
                message: 'La Carrera ha terminado',
                costo: usuariosPorCalificar[i][2]
            });
            return;
        }
    }

    response.status(404).json({
        ok: false,
        message: 'La carrera no ha terminado'
    });
};

const calificarTaxista = (request, response) => {
    console.log('calificarTaxista');
    const body = request.body;

    const schema = {
        num: Joi.string().min(10).max(13).required().regex(/^[0-9]+$/),
        puntaje: Joi.number().integer().greater(-1).less(6).required()
    };

    const {error} = Joi.validate(request.body, schema);

    if (error) {
        return response.status(400).send(error.details[0].message);
    }

    if (usuariosPorCalificar.length === 0) {
        return response.status(404).json({
            ok: true,
            message: 'No tiene carreras pendientes por calificar'
        });
    }

    for (let i = 0; i < usuariosPorCalificar.length; i++) {
        if (usuariosPorCalificar[i][0] === body.num) {
            pool.query('SELECT ingresar_puntaje($1, $2, $3)',
                [parseInt(body.puntaje, 10), usuariosPorCalificar[i][1], body.num], (error, results) => {
                    if (error) {
                        return response.status(400).json({
                            ok: false,
                            err: error
                        });
                    }

                    taxista = usuariosPorCalificar[i][1];
                    usuariosPorCalificar.splice(i, 1);

                    return response.status(200).json({
                        ok: true,
                        message: 'Ha calificado al taxista',
                        puntaje: body.puntaje,
                        taxista: taxista
                    });

                });
        } else if (i === usuariosPorCalificar.length - 1) {
            response.status(404).json({
                ok: true,
                message: 'No tiene carreras pendientes por calificar'
            });
        }
    }

};

const registrarTaxi = (request, response) => {
    const body = request.body;

    const schema = {
        placa: Joi.string().length(6).required().regex(/^[A-Z]{3}[0-9]{3}$/),
        baul: Joi.string().max(25).required().regex(/^[A-Z0-9a-z]+$/),
        soat: Joi.string().required().max(50).regex(/^[0-9]+$/),
        modelo: Joi.string().max(50).required().regex(/^[0-9A-Za-z]+$/),
        marca: Joi.string().max(50).required().regex(/^[0-9A-Za-z]+$/),
        year: Joi.date().min('1900').required()
    };

    const {error} = Joi.validate(request.body, schema);

    if (error) {
        return response.status(400).send(error.details[0].message);
    }

    pool.query('INSERT INTO taxi VALUES ($1, $2, $3, $4, $5, $6)',
        [body.placa, body.baul, body.soat, body.modelo, body.marca, body.year], (error) => {
            if (error) {
                return response.status(400).json({
                    ok: false,
                    err: error,
                    message: 'Otro taxi con esa placa se encuentra registrado'
                });
            }

            response.status(201).json({
                ok: true,
                message: `Taxi registrado con exito`,
                usuario: {
                    placa: body.placa,
                    soat: body.soat,
                    marca: body.marca,
                    modelo: body.modelo
                }
            });
        })
};

const comenzarServicio = (request, response) => {
    const body = request.body;

    const schema = {
        id_taxista: Joi.string().max(20).required().regex(/^[0-9]+$/),
        coordsTaxista: Joi.string().required().regex(/^[(]{1}-{0,1}(((1[0-7][0-9]|[1-9][0-9]|[0-9])[.][0-9]{1,30})|180[.]0{1,30})[,]{1}[" "]{0,1}[-]{0,1}((([1-8][0-9]|[0-9])[.][0-9]{1,30})|90[.]0{1,30})[)]{1}$/),
        placa: Joi.string().length(6).required().regex(/^[A-Z]{3}[0-9]{3}$/)
    };

    const {error} = Joi.validate(request.body, schema);

    if (error) {
        return response.status(400).send(error.details[0].message);
    }

    pool.query('SELECT * FROM loggear_taxista($1, $2, $3)',
        [body.id_taxista, body.coordsTaxista, body.placa], (error, results) => {
            if (error) {
                return response.status(400).json({
                    ok: false,
                    err: error,
                    message: 'El taxi que va a usar se encuentra en uso'
                });
            }

            if (!results.rows[0]) {
                return response.status(400).json({
                    ok: false,
                    err: error,
                    message: 'El taxi que va a usar se encuentra en uso'
                });
            }

            response.status(201).json({
                ok: true,
                message: `Ha comenzado a prestar servicio, aparecera en las busquedas`,
                usuario: {
                    placa: body.placa,
                    nombre: results.rows[0].nombre,
                    identificaicon: body.id_taxista,
                    coordenadas: body.coordsTaxista
                }
            });
        })
};

const terminarServicio = (request, response) => {
    const body = request.body;

    const schema = {
        id_taxista: Joi.string().max(20).required().regex(/^[0-9]+$/)
    };

    const {error} = Joi.validate(request.body, schema);

    if (error) {
        return response.status(400).send(error.details[0].message);
    }

    pool.query('SELECT logout_taxista($1)',
        [body.id_taxista], (error) => {
            if (error) {
                return response.status(400).json({
                    ok: false,
                    err: error,
                    message: 'No se encuentra prestando servicio'
                });
            }

            response.status(200).json({
                ok: true,
                message: `Ha terminado de prestar servicio, no aparecera en busquedas`
            });
        })
};

const pagarSaldoCompleto = (request, response) => {
    const body = request.body;

    const schema = {
        id_taxista: Joi.string().max(20).required().regex(/^[0-9]+$/)
    };

    const {error} = Joi.validate(request.body, schema);

    if (error) {
        return response.status(400).send(error.details[0].message);
    }

    pool.query('select saldo from taxista where id_taxista = $1',
        [body.id_taxista], (error, results) => {
            if (error) {
                return response.status(400).json({
                    ok: false,
                    err: error,
                    message: 'No se pudo completar el pago'
                });
            }

            if (!(results.rows[0])) {
                return response.status(404).json({
                    ok: false,
                    err: error,
                    message: 'El taxista no existe'
                });
            }

            let saldo = results.rows[0].saldo;

            pool.query('SELECT pagar_todo($1)',
                [body.id_taxista], (error) => {
                    if (error) {
                        return response.status(400).json({
                            ok: false,
                            err: error,
                            message: 'No se pudo completar el pago'
                        });
                    }

                    response.status(200).json({
                        ok: true,
                        message: `${saldo} Ha sido añadido a su cuenta`,
                        saldo: 0
                    });
                })
        });
};

const cobrarDeudaCompleta = (request, response) => {
    const body = request.body;

    const schema = {
        num: Joi.string().min(10).max(13).required().regex(/^[0-9]+$/)
    };

    const {error} = Joi.validate(request.body, schema);

    if (error) {
        return response.status(400).send(error.details[0].message);
    }

    pool.query('select deuda from usuario where num_cel_u = $1',
        [body.num], (error, results) => {
            if (error) {
                return response.status(400).json({
                    ok: false,
                    err: error,
                    message: 'No se pudo completar el pago'
                });
            }

            if (!results.rows[0]) {
                return response.status(404).json({
                    ok: false,
                    err: error,
                    message: 'El usuario no existe'
                });
            }

            let deuda = results.rows[0].deuda;

            pool.query('SELECT cobrar_todo($1)',
                [body.num], (error) => {
                    if (error) {
                        return response.status(400).json({
                            ok: false,
                            err: error,
                            message: 'No se pudo completar el pago'
                        });
                    }

                    response.status(200).json({
                        ok: true,
                        message: `Ha pagado toda su deuda para un total de ${deuda}`,
                        deuda: 0
                    });
                })
        });
};

module.exports = {
    createUser, //Crea una cuenta de usuario (roll usuario)
    createTaxista, //Crea una cuenta de taxista (roll taxista)
    getUserById, //Da la info de un usuario especifico (roll usuario)
    deleteUser, //borra al usuario de la base de datos
    updateUser, //Actualiza la info de un usuario en particular (roll usuario)
    loginUser, //Logea al usuario a la aplicacion (roll usuario)
    getDirections, //Retorna las direcciones favoritas del usuario (roll usuario)
    pedirCarrera, //Permite al usuario pedir un taxi (roll usuario)
    createDirFav, //Permite al usuarip guardar una direccion especifica (roll usuario)
    buscarServicio, //Permite al taxista saber si ha sido solicitado, en caso de serlo puede aceptar la carrera (roll taxista)
    confirmarServicio, //Permite al taxista aceptar una carrera si es que lo desea
    notificarCarreraAceptada, //Notifica al usuario que su carrera ha sido aceptada (roll usuario)
    loginTaxista, //Logea al taxista a la aplicacion (roll taxista)
    getDriverById, //Da la info de un taxista especifico (roll taxista)
    terminarCarrera, //Permite al taxista terminar una carrera (roll taxista)
    notificarCarreraTerminada, //Notifica al usuario que la carrera ha terminado (roll usuario)
    calificarTaxista, //Permite al usuario calificar la carrera que acabo de tener (roll usuario)
    registrarTaxi, //Permite al taxista registrar un taxi
    comenzarServicio, //Permite al taxista ponerse en estado disponible para ser encontrado en las busquedas de carrera
    updateDirFav, //Permite al usuario actualizar el nombre de una direccion favorita
    deleteDirFav, //Permite al usuario borrar una direccion favorita
    revisarEstadoUsuario, //Permite a la aplicacion saber en que estado se encuentra el usuario (pidiendo carrera, en plena carrera, etc)
    terminarServicio, //Permite al taxista dejar de prestar servicio para no aparecer en las busquedas de carrera
    revisarEstadoTaxista, //Permite a la aplicacion saber en que estado se encuentra el taxista (En carrera, en busqueda, sin comenzar servicio)
    updateTaxista, //Permite al taxista actualizar su nombre y/o apellido
    pagarSaldoCompleto, //Permite a la aplicacion pagar el saldo que le debe al taxista
    cobrarDeudaCompleta //Permite al usuario pagar la deuda que ha acomulado de todas sus carreras
};