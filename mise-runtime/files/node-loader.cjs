'use strict';
const path = require('node:path');
const launcher = path.join(__dirname, 'bin/node');
process.execPath = launcher;
process.argv[0] = launcher;
