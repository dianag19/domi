const express = require('express');
const app = express();
const db = require('../queries/queries');

app.post('/login/user',db.loginUser);
app.post('/login/driver',db.loginTaxista);

module.exports = app;