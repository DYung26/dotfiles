const fs = require('node:fs');
const path = require('node:path');
const os = require('node:os');
const { execFileSync } = require('node:child_process');

const home = process.env.DOTFILES_HOME || os.homedir();
const configFile = path.join(home, 'Projects', 'dotfiles', 'systemd', 'systemd.env');
if (fs.existsSync(configFile)) {
  for (const line of fs.readFileSync(configFile, 'utf8').split(/\r?\n/)) {
    const match = line.match(/^([A-Za-z_][A-Za-z0-9_]*)=(.*)$/);
    if (match && process.env[match[1]] === undefined) process.env[match[1]] = match[2];
  }
}

const sql = "SELECT env::text FROM mcp_servers WHERE uuid='466c946b-4f73-4e1f-810e-5bbebf321be6'";
const raw = execFileSync('docker', ['exec','metamcp-pg','psql','-U','metamcp_user','-d','metamcp_db','-Atc',sql], {encoding:'utf8'}).trim();
if (!raw) throw new Error('Google Workspace MCP server record not found or env is empty');
const saved = JSON.parse(raw);
const required = ['GOOGLE_OAUTH_CLIENT_ID','GOOGLE_OAUTH_CLIENT_SECRET','FASTMCP_SERVER_AUTH_GOOGLE_JWT_SIGNING_KEY'];
for (const key of required) if (!saved[key]) throw new Error('Missing required saved variable: '+key);
if (String(saved.MCP_ENABLE_OAUTH21).toLowerCase() !== 'true') throw new Error('OAuth 2.1 is not enabled in the saved server env');

const requiredConfig = ['WORKSPACE_EXTERNAL_URL','OAUTH_ALLOWED_ORIGINS','GOOGLE_OAUTH_REDIRECT_URI','GOOGLE_MCP_CREDENTIALS_DIR'];
for (const key of requiredConfig) if (!process.env[key]) throw new Error('Missing device config in systemd.env: '+key);

const env = {
  GOOGLE_OAUTH_CLIENT_ID: saved.GOOGLE_OAUTH_CLIENT_ID,
  GOOGLE_OAUTH_CLIENT_SECRET: saved.GOOGLE_OAUTH_CLIENT_SECRET,
  FASTMCP_SERVER_AUTH_GOOGLE_JWT_SIGNING_KEY: saved.FASTMCP_SERVER_AUTH_GOOGLE_JWT_SIGNING_KEY,
  MCP_ENABLE_OAUTH21: 'true',
  WORKSPACE_MCP_HOST: process.env.WORKSPACE_MCP_HOST || '0.0.0.0',
  WORKSPACE_MCP_PORT: process.env.WORKSPACE_MCP_PORT || '8003',
  GOOGLE_MCP_CREDENTIALS_DIR: process.env.GOOGLE_MCP_CREDENTIALS_DIR,
  WORKSPACE_EXTERNAL_URL: process.env.WORKSPACE_EXTERNAL_URL,
  OAUTH_ALLOWED_ORIGINS: process.env.OAUTH_ALLOWED_ORIGINS,
  GOOGLE_OAUTH_REDIRECT_URI: process.env.GOOGLE_OAUTH_REDIRECT_URI
};

const serviceDir = path.join(home, 'Services', 'workspace-mcp');
fs.mkdirSync(serviceDir, {recursive:true});
const out = path.join(serviceDir, '.env');
fs.writeFileSync(out, Object.entries(env).map(([k,v]) => k+'='+String(v).replace(/[\r\n]/g,'')).join(String.fromCharCode(10))+String.fromCharCode(10), {mode:0o600});
fs.chmodSync(out, 0o600);
fs.chownSync(serviceDir, process.getuid(), process.getgid());
fs.chownSync(out, process.getuid(), process.getgid());
process.stdout.write('Created protected environment file with '+Object.keys(env).length+' settings; secret values were not displayed.'+String.fromCharCode(10));
