"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.lstat = void 0;
const original_fs_1 = require("original-fs");
const util_1 = require("util");
exports.lstat = util_1.promisify(original_fs_1.lstat);
//# sourceMappingURL=lstat.js.map