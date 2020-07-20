"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const pathsCommand_1 = require("./pathsCommand");
const mavensMateCodeCoverage_1 = require("../../vscode/mavensMateCodeCoverage");
const vscode = require("vscode");
const path = require("path");
module.exports = class GetCoverage extends pathsCommand_1.PathsCommand {
    static create() {
        return new GetCoverage();
    }
    constructor() {
        super('Get Apex Code Coverage', 'get-coverage');
        this.mavensMateCodeCoverage = mavensMateCodeCoverage_1.MavensMateCodeCoverage.getInstance();
    }
    confirmPath() {
        if (!this.checkIsMetadata()) {
            throw new Error(`File is not metadata: ${this.filePath}`);
        }
        else if (this.filePath.indexOf('apex-scripts') !== -1) {
            throw new Error(`Local Apex Scripts aren't covered by tests`);
        }
        else {
            return super.confirmPath();
        }
    }
    onSuccess(response) {
        return super.onSuccess(response)
            .then(() => this.handleCoverageResponse(response));
    }
    handleCoverageResponse(response) {
        if (response.result && response.result != []) {
            for (let pathEnd in response.result) {
                let workspaceRoot = vscode.workspace.rootPath;
                let filePath = path.join(workspaceRoot, 'src', 'classes', pathEnd);
                let coverageResult = response.result[pathEnd];
                let uncoveredLines = coverageResult.uncoveredLines;
                this.mavensMateCodeCoverage.report(filePath, coverageResult.percentCovered, uncoveredLines);
            }
        }
        else {
            let message = `No Apex Code Coverage Available: ${this.baseName} (${this.filePath})`;
            this.mavensMateChannel.appendLine(message);
            vscode.window.showWarningMessage(message);
        }
    }
};
//# sourceMappingURL=getCoverage.js.map