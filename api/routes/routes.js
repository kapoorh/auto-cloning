const router = require('express').Router();
const clonevmcontroller = require('../controller/clonevmcontroller');

router.get('/', function (req, res) {
    res.send('Its working...');
  });


router.post('/clonevm', clonevmcontroller.clonevm);

module.exports = router;
