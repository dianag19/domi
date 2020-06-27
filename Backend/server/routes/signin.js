const express = require('express');
const app = express();
const db = require('../queries/queries');


app.post('/signin/user',db.createUser);
app.post('/signin/driver',db.createTaxista);


module.exports = app;