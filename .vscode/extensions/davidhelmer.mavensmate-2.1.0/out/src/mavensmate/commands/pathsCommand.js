"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const clientCommand_1 = require("./clientCommand");
const vscode = require("vscode");
const Promise = require("bluebird");
const path = require("path");
class PathsCommand extends clientCommand_1.ClientCommand {
    constructor(label, id) {
        super(label, id);
    }
    execute(selectedResource) {
        if (selectedResource && selectedResource.scheme === 'file') {
            this.filePath = selectedResource.fsPath;
        }
        else if (vscode.window.activeTextEditor && vscode.window.activeTextEditor.document) {
            this.filePath = vscode.window.activeTextEditor.document.uri.fsPath;
        }
        return this.confirmPath()
            .then(() => {
            this.body.paths = [this.filePath];
            return super.execute();
        });
    }
    confirmPath() {
        if (this.filePath && this.filePath.length > 0) {
            this.baseName = path.basename(this.filePath);
            return Promise.resolve(true);
        }
        else {
            throw new Error(`A file path is required for ${this.label}`);
        }
    }
    checkIsMetadata() {
        let isMetadata = false;
        const ignoredFileNames = ['package.xml', 'destructiveChanges.xml', 'destructiveChangesPost.xml', 'destructiveChangesPre.xml'];
        if (this.filePath) {
            let srcDirectoryPath = path.join(vscode.workspace.rootPath, 'src');
            let underWorkspaceSrcDirectory = this.filePath.startsWith(srcDirectoryPath);
            let ignoredFileNamesContainsBaseName = ignoredFileNames.indexOf(this.baseName) == -1;
            isMetadata = underWorkspaceSrcDirectory && ignoredFileNamesContainsBaseName;
        }
        return isMetadata;
    }
    onStart() {
        return super.onStart()
            .then(() => {
            return this.outputPathProcessed();
        });
    }
    outputPathProcessed() {
        let message = `${this.baseName} (${this.filePath})`;
        return this.mavensMateChannel.appendLine(message);
    }
    onSuccess(response) {
        return super.onSuccess(response)
            .then(() => {
            this.outputPathProcessed();
            return response;
        });
    }
    onFailure(response) {
        return super.onFailure(response)
            .then(() => {
            this.outputPathProcessed().then(response);
            return response;
        });
    }
}
exports.PathsCommand = PathsCommand;
//# sourceMappingURL=pathsCommand.js.map