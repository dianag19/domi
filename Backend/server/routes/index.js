const express = require('express');
const app = express();
const cors = require('cors');


app.use(cors());
/*app.use((req, res, next) => {
    res.header("Access-Control-Allow-Origin", "*");
    res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
    res.header("Access-Control-Allow-Methods", "GET, POST, OPTIONS, PUT, DELETE");
    res.header("Allow', 'GET, POST, OPTIONS, PUT, DELETE");
    next();
});*/

app.use(require('./signin'));
app.use(require('./login'));
app.use(require('./usuario'));
app.use(require('./taxista'));

module.exports = app;
