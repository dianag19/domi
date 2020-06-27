//==========PORT===========//
process.env.PORT = process.env.PORT || 3000;
//=========================//

var pg = require('pg');
//or native libpq bindings
//var pg = require('pg').native

// var conString = "postgres://enptunho:OZpMB-cnrs9s0DpTj3LXXM5CIfJ1kLCw@ruby.db.elephantsql.com:5432/enptunho" //Can be found in the Details page
// var client = new pg.Client(conString);
// client.connect(function(err) {
// if(err) {
//   return console.error('could not connect to postgres', err);
// }

// });
//==========DB connection =====//
module.exports.connectionData = process.env.connectionData || {
    user: 'enptunho',
    host: 'ruby.db.elephantsql.com',
    database: 'enptunho',
    password: 'OZpMB-cnrs9s0DpTj3LXXM5CIfJ1kLCw',
    port: 5432,
};
//==========================//

//=========SEED FOR HASH FUNCTIONS ====//
// process.env.SEED = process.env.SEED || 'OZpMB-cnrs9s0DpTj3LXXM5CIfJ1kLCw';

// module.exports.connectionDataUser = process.env.connectionDataUser || {
//     user: 'enptunho',
//     host: 'ruby.db.elephantsql.com',
//     database: 'enptunho',
//     password: 'OZpMB-cnrs9s0DpTj3LXXM5CIfJ1kLCw',
//     port: 5432,
// };
