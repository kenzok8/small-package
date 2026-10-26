#!/usr/bin/ucode
/*
 * SPDX-License-Identifier: GPL-2.0-only
 *
 * Copyright (C) 2026
 */

'use strict';

import { cursor } from 'uci';
import { reconcileUrltestNodes } from 'homeproxy';

const uci = cursor();
const config = 'homeproxy';
uci.load(config);

const result = reconcileUrltestNodes(uci, config, (message) => {
	print(sprintf('[URLTEST] %s\n', message));
});

if (result.changed && uci.commit(config) !== true)
	exit(1);
