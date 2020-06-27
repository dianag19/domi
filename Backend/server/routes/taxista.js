const express = require('express');
const app = express();
const db = require('../queries/queries');
const {verificaToken, verificaUserRole} = require('../midlewares/midlewares');

//comenzarCarrera

app.get('/taxista/:id',verificaToken,db.getDriverById);
app.get('/taxista/revisarEstadoTaxista/:id_taxista', db.revisarEstadoTaxista);

app.post('/taxista/buscarServicio', db.buscarServicio);
app.post('/taxista/terminarCarrera', db.terminarCarrera);
app.post('/taxista/registrarTaxi', db.registrarTaxi);
app.post('/taxista/comenzarServicio', db.comenzarServicio);
app.post('/taxista/confirmarServicio', db.confirmarServicio);

app.put('/taxista/terminarServicio', db.terminarServicio);
app.put('/taxista/updateTaxista', db.updateTaxista);
app.put('/profile/pagar',db.cobrarDeudaCompleta);

module.exports = app;