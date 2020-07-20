'use strict';
Object.defineProperty(exports, "__esModule", { value: true });
const vscode = require("vscode");
const mavensMateChannel_1 = require("../src/vscode/mavensMateChannel");
const projectSettings_1 = require("../src/mavensmate/projectSettings");
const mavensMateClient_1 = require("../src/mavensmate/mavensMateClient");
const mavensMateStatus_1 = require("../src/vscode/mavensMateStatus");
const mavensMateCodeCoverage_1 = require("../src/vscode/mavensMateCodeCoverage");
const CommandRegistrar = require("../src/vscode/commandRegistrar");
const mavensMateConfiguration_1 = require("./vscode/mavensMateConfiguration");
class MavensMateExtension {
    static create(context) {
        return new MavensMateExtension(context);
    }
    constructor(context) {
        this.context = context;
    }
    activate(context) {
        this.mavensMateChannel = mavensMateChannel_1.MavensMateChannel.getInstance();
        this.mavensMateStatus = mavensMateStatus_1.MavensMateStatus.getInstance();
        this.mavensMateClient = mavensMateClient_1.MavensMateClient.getInstance();
        this.mavensMateCodeCoverage = mavensMateCodeCoverage_1.MavensMateCodeCoverage.getInstance();
        this.mavensMateChannel.appendStatus(`Update: August 7, 2017
        MavensMate is no longer available for download and is not being actively developed or supported. We recommend using Salesforce's official Visual Studio Code plugin for building Salesforce applications.`);
    }
    checkProjectSettingsAndSubscribe() {
        if (projectSettings_1.ProjectSettings.hasProjectSettings()) {
            let projectSettings = projectSettings_1.ProjectSettings.getProjectSettings();
            this.mavensMateChannel.appendStatus(`Instantiating with Project: ${projectSettings.projectName} (${projectSettings.instanceUrl})`);
            return this.subscribeToEvents();
        }
        else {
            this.mavensMateChannel.appendStatus(`Instantiating without Project`);
        }
    }
    instantiateWithoutProject() {
        let withProject = false;
        CommandRegistrar.registerCommands();
    }
    subscribeToEvents() {
        let saveEvent = vscode.workspace.onDidSaveTextDocument((textDocument) => {
            let compileOnSaveConfigured = mavensMateConfiguration_1.getConfiguration('mavensMate.compileOnSave');
            let isApexScript = textDocument.fileName.includes('apex-scripts');
            let isMetadata = textDocument.fileName.includes('src')
                && !textDocument.fileName.endsWith('package.xml')
                && !textDocument.fileName.endsWith('destructiveChanges.xml')
                && !textDocument.fileName.endsWith('destructiveChangesPost.xml')
                && !textDocument.fileName.endsWith('destructiveChangesPre.xml');
            if (!compileOnSaveConfigured) {
                console.info('MavensMate: compileOnSave is not configured.');
            }
            else if (isApexScript) {
                console.info('MavensMate: silently ignoring the saving of a local apex script. (OK you got me, this isn\'t necessarily silence)');
            }
            else if (isMetadata) {
                return vscode.commands.executeCommand('mavensmate.compileFile', textDocument.uri);
            }
            else {
                console.info('MavensMate: silently ignoring the saving of a non-metadata file (not under a src directory');
            }
        });
        this.context.subscriptions.push(saveEvent);
        this.mavensMateChannel.appendStatus('Subscribed to events');
    }
    deactivate() {
        this.mavensMateChannel.appendStatus('Deactivating');
        this.mavensMateChannel.dispose();
        this.mavensMateClient.dispose();
        this.mavensMateStatus.dispose();
        this.mavensMateCodeCoverage.dispose();
        console.info(`MavensMate: Finished Deactivating`);
    }
}
exports.MavensMateExtension = MavensMateExtension;
//# sourceMappingURL=mavensMateExtension.js.map