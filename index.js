const express = require('express');
var app = express();
const bodyparser = require('body-parser');
const routes = require('./api/routes/routes');

app.use(bodyparser.json());

app.use('/api', routes);

app.listen(3000, () => console.log('Express server is runnig at port no : 3000'));