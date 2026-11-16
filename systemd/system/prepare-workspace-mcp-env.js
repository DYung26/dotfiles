import * as fs from 'node:fs';
import * as path from 'node:path';
import * as os from 'node:os';

const home = process.env.DOTFILES_HOME || os.homedir();
const configDirectory = path.join(home, '.config', 'dotfiles', 'systemd');

for (const filename of ['systemd.env.common', 'systemd.env']) {
  const configFile = path.join(configDirectory, filename);
  if (!fs.existsSync(configFile)) {
    throw new Error('Missing systemd configuration file: ' + configFile);
  }

  for (const line of fs.readFileSync(configFile, 'utf8').split(/\r?\n/)) {
    const match = line.match(/^([A-Za-z_][A-Za-z0-9_]*)=(.*)$/);
    if (match && process.env[match[1]] === undefined) {
      process.env[match[1]] = match[2];
    }
  }
}

const serviceDirectory = path.join(home, 'Services', 'workspace-mcp');
const outputFile = path.join(serviceDirectory, '.env');
if (!fs.existsSync(outputFile)) {
  throw new Error('Refusing to create Workspace MCP env without an existing credentials file: ' + outputFile);
}
if (fs.lstatSync(outputFile).isSymbolicLink()) {
  throw new Error('Refusing to overwrite a symlinked Workspace MCP env file: ' + outputFile);
}

const existingLines = fs.readFileSync(outputFile, 'utf8').split(/\r?\n/);
const existing = new Map();
for (const line of existingLines) {
  const match = line.match(/^([A-Za-z_][A-Za-z0-9_]*)=(.*)$/);
  if (match) existing.set(match[1], match[2]);
}

const requiredSecrets = [
  'GOOGLE_OAUTH_CLIENT_ID',
  'GOOGLE_OAUTH_CLIENT_SECRET',
  'FASTMCP_SERVER_AUTH_GOOGLE_JWT_SIGNING_KEY'
];
for (const key of requiredSecrets) {
  if (!existing.get(key)) {
    throw new Error('Missing required existing Workspace MCP credential: ' + key);
  }
}
if (String(existing.get('MCP_ENABLE_OAUTH21')).toLowerCase() !== 'true') {
  throw new Error('OAuth 2.1 is not enabled in the existing Workspace MCP env');
}

const requiredConfig = [
  'WORKSPACE_EXTERNAL_URL',
  'OAUTH_ALLOWED_ORIGINS',
  'GOOGLE_OAUTH_REDIRECT_URI',
  'GOOGLE_MCP_CREDENTIALS_DIR'
];
for (const key of requiredConfig) {
  if (!process.env[key]) {
    throw new Error('Missing selected device configuration: ' + key);
  }
}

const deviceConfig = {
  WORKSPACE_MCP_HOST: process.env.WORKSPACE_MCP_HOST || '0.0.0.0',
  WORKSPACE_MCP_PORT: process.env.WORKSPACE_MCP_PORT || '8003',
  GOOGLE_MCP_CREDENTIALS_DIR: process.env.GOOGLE_MCP_CREDENTIALS_DIR,
  WORKSPACE_EXTERNAL_URL: process.env.WORKSPACE_EXTERNAL_URL,
  OAUTH_ALLOWED_ORIGINS: process.env.OAUTH_ALLOWED_ORIGINS,
  GOOGLE_OAUTH_REDIRECT_URI: process.env.GOOGLE_OAUTH_REDIRECT_URI
};

const seen = new Set();
const outputLines = [];
for (const line of existingLines) {
  const match = line.match(/^([A-Za-z_][A-Za-z0-9_]*)=(.*)$/);
  if (!match || !Object.hasOwn(deviceConfig, match[1])) {
    outputLines.push(line);
    continue;
  }

  const key = match[1];
  if (seen.has(key)) continue;
  seen.add(key);
  outputLines.push(key + '=' + String(deviceConfig[key]).replace(/[\r\n]/g, ''));
}

for (const [key, value] of Object.entries(deviceConfig)) {
  if (!seen.has(key)) {
    outputLines.push(key + '=' + String(value).replace(/[\r\n]/g, ''));
  }
}

while (outputLines.length && outputLines[outputLines.length - 1] === '') {
  outputLines.pop();
}
const output = outputLines.join('\n') + '\n';
const temporaryFile = outputFile + '.tmp-' + process.pid;

try {
  fs.writeFileSync(temporaryFile, output, { mode: 0o600 });
  fs.chmodSync(temporaryFile, 0o600);
  fs.chownSync(temporaryFile, process.getuid(), process.getgid());
  fs.renameSync(temporaryFile, outputFile);
  fs.chmodSync(outputFile, 0o600);
} finally {
  if (fs.existsSync(temporaryFile)) fs.unlinkSync(temporaryFile);
}

process.stdout.write('Updated protected Workspace MCP env; preserved existing credentials and applied ' + Object.keys(deviceConfig).length + ' device settings.\n');
