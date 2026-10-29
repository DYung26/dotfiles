# Windows MCP shell and Cloudflare tunnel

This setup uses Windows Task Scheduler at user logon, not systemd. The installer builds a Windows-native mcp-shell executable from the local `DYung26/mcp-shell` checkout, installs mcp-proxy with uv, installs cloudflared, creates a Windows-specific security policy, and writes %LOCALAPPDATA%\McpShell\cloudflared\config.yml. The proxy listens only on 127.0.0.1:8090, and Cloudflare routes laptop-ab9612ik-mcp.dyung.me to that port.

Run in PowerShell as the normal user from the synced dotfiles repository. By default, the installer looks for `..\mcp-shell` or `..\mcp-shell-src` next to the dotfiles checkout. You can pass `-McpShellSource <path>` to select another checkout. If neither exists, it clones your fork to `%LOCALAPPDATA%\McpShell\src`.

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\windows\mcp-shell\Install-McpWindows.ps1
```

The installer registers McpShellProxy-Laptop to start at user logon. It also creates Cloudflared-Mcp-Laptop but leaves that task disabled by default.

The tunnel credentials and Cloudflare origin certificate are kept in %LOCALAPPDATA%\McpShell\cloudflared, outside the synced dotfiles checkout. On first setup, the installer opens a one-time Cloudflare browser login and provisions a local credential for the existing mcp.laptop-ab9612ik tunnel. No private credential needs to be committed or synced between devices.

Security note: the current mcp-shell policy mirrors the Linux hosts' legacy shell-execution mode. Do not treat allowed_commands as a strong sandbox in legacy mode. Before enabling the public tunnel, configure Cloudflare Access or another real authentication layer for laptop-ab9612ik-mcp.dyung.me. After that, run:

```powershell
.\windows\mcp-shell\Install-McpWindows.ps1 -EnableCloudflared
```

Logs are under %LOCALAPPDATA%\McpShell\logs. The installer does not open an inbound Windows Firewall port.

## Native OpenSSH access over Tailscale

Windows does not run the Tailscale SSH server; use Windows OpenSSH Server for ordinary SSH over the Tailscale network. After pulling the dotfiles, open PowerShell as Administrator **under the Windows account you intend to SSH into** and run:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\windows\ssh\Configure-OpenSSH-Server.ps1
```

The script validates that the existing `id_rsa.pub` matches the RSA key already used by VPS and Arch, then installs that public key in Windows OpenSSH's administrator authorized-keys file and restricts inbound SSH firewall access to Tailscale addresses. It does not copy private keys, generate keys, or remove existing keys. This script must be run locally because the laptop currently rejects key-based authentication, and Tailscale SSH's server component is not available on Windows.
