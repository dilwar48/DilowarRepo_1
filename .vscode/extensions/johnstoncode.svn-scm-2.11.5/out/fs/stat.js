"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.stat = void 0;
const original_fs_1 = require("original-fs");
const util_1 = require("util");
exports.stat = util_1.promisify(original_fs_1.stat);
//# sourceMappingURL=stat.js.map