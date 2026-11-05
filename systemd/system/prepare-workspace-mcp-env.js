const fs = require('node:fs');
const cp = require('node:child_process');
const { execFileSync } = cp;
const sql = "SELECT env::text FROM mcp_servers WHERE uuid='466c946b-4f73-4e1f-810e-5bbebf321be6'";
const raw = execFileSync('docker', ['exec','metamcp-pg','psql','-U','metamcp_user','-d','metamcp_db','-Atc',sql], {encoding:'utf8'}).trim();
if (!raw) throw new Error('Google Workspace MCP server record not found or env is empty');
const saved = JSON.parse(raw);
const required = ['GOOGLE_OAUTH_CLIENT_ID','GOOGLE_OAUTH_CLIENT_SECRET','FASTMCP_SERVER_AUTH_GOOGLE_JWT_SIGNING_KEY'];
for (const key of required) if (!saved[key]) throw new Error('Missing required saved variable: '+key);
if (String(saved.MCP_ENABLE_OAUTH21).toLowerCase() !== 'true') throw new Error('OAuth 2.1 is not enabled in the saved server env');
const env = {
  GOOGLE_OAUTH_CLIENT_ID: saved.GOOGLE_OAUTH_CLIENT_ID,
  GOOGLE_OAUTH_CLIENT_SECRET: saved.GOOGLE_OAUTH_CLIENT_SECRET,
  FASTMCP_SERVER_AUTH_GOOGLE_JWT_SIGNING_KEY: saved.FASTMCP_SERVER_AUTH_GOOGLE_JWT_SIGNING_KEY,
  MCP_ENABLE_OAUTH21: 'true',
  WORKSPACE_MCP_HOST: '0.0.0.0',
  WORKSPACE_MCP_PORT: '8003',
  GOOGLE_MCP_CREDENTIALS_DIR: '/home/nextjs/.google_workspace_mcp/credentials',
  WORKSPACE_EXTERNAL_URL: 'https://workspace-mcp.dyung.me',
  GOOGLE_OAUTH_REDIRECT_URI: 'https://workspace-mcp.dyung.me/oauth2callback'
};
fs.mkdirSync('/home/dyung/Services/workspace-mcp', {recursive:true});
const out='/home/dyung/Services/workspace-mcp/.env';
fs.writeFileSync(out, Object.entries(env).map(([k,v])=>k+'='+String(v).replace(/[\r\n]/g,'')).join(String.fromCharCode(10))+String.fromCharCode(10), {mode:0o600});
fs.chmodSync(out,0o600);
fs.chownSync('/home/dyung/Services/workspace-mcp',1000,1000);
process.stdout.write('Created protected environment file with '+Object.keys(env).length+' settings; secret values were not displayed.'+String.fromCharCode(10));
