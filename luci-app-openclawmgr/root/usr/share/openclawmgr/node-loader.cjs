'use strict';
// Explicit loader execution does not preserve a directly executable Node
// path. npm and child_process.fork must re-enter the launcher on a musl host.
const path = require('node:path');
const launcher = path.join(__dirname, 'bin/node');
process.execPath = launcher;
process.argv[0] = launcher;
