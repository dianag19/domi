const express = require('express');
const app = express();
const db = require('../queries/queries');
const {verificaToken, verificaUserRole} = require('../midlewares/midlewares');



app.get('/profile/:id',verificaToken, db.getUserById);
app.get('/profile/dirfav/:id',verificaToken, db.getDirections);
app.get('/profile/revisarEstado/:num', db.revisarEstadoUsuario);

app.post('/profile/dirfav', db.createDirFav); //updateUser
app.post('/profile/pedirCarrera', db.pedirCarrera);
app.post('/profile/confirmarCarrera', db.notificarCarreraAceptada);
app.post('/profile/notificarCarreraTerminada', db.notificarCarreraTerminada);
app.post('/profile/calificarTaxista', db.calificarTaxista);

app.put('/profile/updateUser', db.updateUser);
app.put('/profile/updateDirFav', db.updateDirFav);
app.put('/taxista/cobrar',db.pagarSaldoCompleto);

app.delete('/profile/deleteUser', db.deleteUser);
app.delete('/profile/deleteDirFav', db.deleteDirFav);



module.exports = app;