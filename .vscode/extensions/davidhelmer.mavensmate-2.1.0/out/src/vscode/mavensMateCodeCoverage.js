"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const vscode = require("vscode");
class MavensMateCodeCoverage {
    constructor() {
        this.decorationType = this.getDecorationType();
        this.uncoveredRangesByPath = {};
        this.percentCoveredByPath = {};
        this.coverageStatus = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Left, 1);
        this.coverageStatus.command = 'mavensmate.getCoverage';
        this.refreshActivePercentCovered();
        this.coverageStatus.show();
        vscode.window.onDidChangeActiveTextEditor((textEditor) => {
            this.onDidChangeActiveTextEditor(textEditor);
        });
    }
    static getInstance() {
        if (MavensMateCodeCoverage._instance == null) {
            MavensMateCodeCoverage._instance = new MavensMateCodeCoverage();
        }
        return MavensMateCodeCoverage._instance;
    }
    getDecorationType() {
        let options = {
            isWholeLine: true,
            backgroundColor: 'rgba(215, 44, 44, 0.3)'
        };
        return vscode.window.createTextEditorDecorationType(options);
    }
    onDidChangeActiveTextEditor(textEditor) {
        if (textEditor.document.languageId === 'apex') {
            this.refreshUncoveredDecorations();
            this.refreshActivePercentCovered();
            this.coverageStatus.show();
        }
        else {
            this.coverageStatus.hide();
        }
    }
    report(fsPath, percentCovered, uncoveredLines) {
        let uncoveredRanges = uncoveredLines.map(asRange);
        this.uncoveredRangesByPath[fsPath] = uncoveredRanges;
        this.percentCoveredByPath[fsPath] = percentCovered;
        this.refreshActivePercentCovered();
        this.refreshUncoveredDecorations();
    }
    clearReport(fsPath, percentCovered) {
        this.percentCoveredByPath[fsPath] = percentCovered;
        this.refreshActivePercentCovered();
        this.clearDecorations();
    }
    refreshUncoveredDecorations() {
        for (let textEditor of vscode.window.visibleTextEditors) {
            let uncoveredRanges = this.uncoveredRangesByPath[textEditor.document.fileName];
            if (uncoveredRanges !== undefined) {
                textEditor.setDecorations(this.decorationType, uncoveredRanges);
            }
        }
    }
    clearDecorations() {
        var textEditor = vscode.window.activeTextEditor;
        let options = {
            isWholeLine: true,
            backgroundColor: 'rgba(255, 255, 255, 1.0)'
        };
        var decoration = vscode.window.createTextEditorDecorationType(options);
        var lineNumber = textEditor.document.lineCount;
        var range = new vscode.Range(new vscode.Position(0, 0), new vscode.Position(lineNumber - 1, 0));
        textEditor.setDecorations(decoration, [range]);
    }
    refreshActivePercentCovered() {
        if (vscode.window.activeTextEditor && vscode.window.activeTextEditor.document) {
            let activePath = vscode.window.activeTextEditor.document.uri.fsPath;
            if (this.percentCoveredByPath[activePath] != undefined) {
                let percentCovered = this.percentCoveredByPath[activePath];
                this.coverageStatus.text = `${percentCovered}% Covered`;
            }
            else {
                this.coverageStatus.text = `Get Test Coverage`;
            }
        }
    }
    dispose() {
        this.coverageStatus.dispose();
    }
}
MavensMateCodeCoverage._instance = null;
exports.MavensMateCodeCoverage = MavensMateCodeCoverage;
function asRange(lineNumber) {
    let vscodeLineNumber = lineNumber - 1;
    let start = new vscode.Position(vscodeLineNumber, 0);
    let end = new vscode.Position(vscodeLineNumber, 0);
    return new vscode.Range(start, end);
}
//# sourceMappingURL=mavensMateCodeCoverage.js.map