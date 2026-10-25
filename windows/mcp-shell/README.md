# Windows MCP shell and Cloudflare tunnel

This setup uses Windows Task Scheduler at user logon, not systemd. The installer builds a Windows-native mcp-shell executable, installs mcp-proxy with uv, installs cloudflared, creates a Windows-specific security policy, and writes %USERPROFILE%\.cloudflared\config.yml. The proxy listens only on 127.0.0.1:8090, and Cloudflare routes laptop-ab9612ik-mcp.dyung.me to that port.

Run in PowerShell as the normal user from the synced dotfiles repository:

    Set-ExecutionPolicy -Scope Process Bypass
    .\windows\mcp-shell\Install-McpWindows.ps1

The installer registers McpShellProxy-Laptop to start at user logon. It also creates Cloudflared-Mcp-Laptop but leaves that task disabled by default.

The tunnel credential is intentionally excluded from Git. If a tunnel credential JSON file is already available in cloudflared\.cloudflared, the installer will copy it locally. Otherwise, it runs cloudflared tunnel login and provisions the credential for the existing mcp.laptop-ab9612ik tunnel. This is an interactive, one-time Cloudflare authorization; no private credential needs to be committed or transferred over SSH.

Security note: the current mcp-shell policy mirrors the Linux hosts' legacy shell-execution mode. Do not treat allowed_commands as a strong sandbox in legacy mode. Before enabling the public tunnel, configure Cloudflare Access or another real authentication layer for laptop-ab9612ik-mcp.dyung.me. After that, run:

    .\windows\mcp-shell\Install-McpWindows.ps1 -EnableCloudflared

Logs are under %LOCALAPPDATA%\McpShell\logs. The installer does not open an inbound Windows Firewall port.
