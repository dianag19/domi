const Pool = require('pg').Pool;
const connectionData = require('./config/config').connectionData;

const express = require('express');
const app = express();
const bodyParser = require('body-parser');
const request = require('request');
const async = require('async');
const pool = new Pool(connectionData);

require('./config/config');

//Parse application/x-www-form-urlencoded
app.use(bodyParser.urlencoded({ extended: false }));

// parse application/Json
app.use(bodyParser.json());

//Router
app.use(require('./routes/index'));
app.get('/upcoming', (request, response) => {
    pool.query('SELECT * FROM usuario', (error, results) => {
                if (error) {
                    return response.status(400).json({
                        ok: false,
                        err: error
                    });
                }

                response.status(201).json({
                    ok: true,
                    message: results.rows,
                    
                });
            })
    //response.json({'itworks' : 'yes'})
})
app.listen(process.env.PORT, ()=>{
    console.log('Listen on port:',process.env.PORT);
});





// app.listen('8010', () => {
//     console.log('Listening on port 8010')
// });