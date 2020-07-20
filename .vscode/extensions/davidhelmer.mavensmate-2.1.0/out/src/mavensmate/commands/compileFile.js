"use strict";
const pathsCommand_1 = require("./pathsCommand");
const compileResponseHandler_1 = require("../handlers/compileResponseHandler");
const vscode = require("vscode");
let languagesToCompileOnSave = new Set(['apex', 'visualforce', 'html', 'xml', 'javascript', 'css']);
class CompileFile extends pathsCommand_1.PathsCommand {
    static create(label) {
        if (!label) {
            label = 'Compile File';
        }
        return new CompileFile(label);
    }
    constructor(label) {
        super(label, 'compile-metadata');
    }
    confirmPath() {
        let uriToOpen = vscode.Uri.file(this.filePath);
        let confirmPromise = vscode.workspace.openTextDocument(uriToOpen)
            .then((textDocument) => {
            if (!this.checkIsMetadata()) {
                throw new Error(`File is not metadata: ${this.filePath}`);
            }
            else if (!languagesToCompileOnSave.has(textDocument.languageId)) {
                throw new Error(`Can not compile this file: ${this.filePath}`);
            }
            else if (this.filePath.includes('apex-scripts')) {
                throw new Error(`Local Apex Scripts can't be compiled. You can run them with Run Apex Script`);
            }
            else if (this.filePath.includes('resource-bundles')) {
                throw new Error(`Files inside Resource Bundles cannot be compiled. Use Deploy Resource Bundle instead`);
            }
            else {
                return super.confirmPath();
            }
        });
        return confirmPromise;
    }
    onSuccess(response) {
        return compileResponseHandler_1.handleCompileResponse(response)
            .then(() => super.onSuccess(response));
    }
}
module.exports = CompileFile;
//# sourceMappingURL=compileFile.js.map