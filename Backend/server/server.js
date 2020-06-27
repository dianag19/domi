const express = require('express');
const app = express();
const bodyParser = require('body-parser');
require('./config/config');

//Parse application/x-www-form-urlencoded
app.use(bodyParser.urlencoded({ extended: false }));

// parse application/Json
app.use(bodyParser.json());

//Router
app.use(require('./routes/index'));

app.listen(process.env.PORT, ()=>{
    console.log('Listen on port:',process.env.PORT);
});

