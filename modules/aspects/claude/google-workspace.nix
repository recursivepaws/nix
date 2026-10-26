{ inputs, den, ... }:
{
  flake-file.inputs.google-workspace-mcp = {
    url = "github:taylorwilsdon/google_workspace_mcp/v2.2.1";
    flake = false;
  };

  # Pulled in by claude.nix for every user; mcp-servers options come from there.
  den.aspects.google-workspace = {
    homeManager =
      { pkgs, config, ... }:
      let
        port = 8000;
        clientSecret = "${config.home.homeDirectory}/.google_workspace_mcp/client_secret.json";
        # HACK: needs fastmcp 4 and mcp 2, neither in nixpkgs yet. uv syncs the repo's uv.lock into a
        # per-user venv on first launch; main.py runs in place since setuptools can't write egg-info into the store.
        workspace-mcp = pkgs.writeShellScript "workspace-mcp" ''
          export UV_PROJECT_ENVIRONMENT="${config.xdg.cacheHome}/workspace-mcp"
          export UV_PYTHON=${pkgs.python3}/bin/python3
          export UV_PYTHON_DOWNLOADS=never
          ${pkgs.uv}/bin/uv sync --frozen --no-dev --extra disk --no-install-project --project ${inputs.google-workspace-mcp} >&2
          exec "$UV_PROJECT_ENVIRONMENT/bin/python" ${inputs.google-workspace-mcp}/main.py "$@"
        '';
      in
      {
        # HTTP transport with MCP OAuth 2.1, so Claude Code signs in via /mcp like the hosted servers.
        # Upstream calls stdio the legacy path: no MCP-level auth, Google login per tool call.
        systemd.user.services.workspace-mcp = {
          Unit = {
            Description = "Google Workspace MCP server";
            # The server exits without the OAuth client file, so stay inactive until it exists.
            ConditionPathExists = clientSecret;
          };
          Service = {
            ExecStart = "${workspace-mcp} --transport streamable-http";
            Environment = [
              "MCP_ENABLE_OAUTH21=true"
              "WORKSPACE_MCP_HOST=127.0.0.1"
              "WORKSPACE_MCP_PORT=${toString port}"
              "GOOGLE_CLIENT_SECRET_PATH=${clientSecret}"
              # Plain http on loopback; oauthlib rejects a non-https redirect URI otherwise.
              "OAUTHLIB_INSECURE_TRANSPORT=1"
              # Default is in-memory, which would force a new /mcp login after every restart.
              "WORKSPACE_MCP_OAUTH_PROXY_STORAGE_BACKEND=disk"
            ];
            Restart = "on-failure";
            RestartSec = 5;
          };
          Install.WantedBy = [ "default.target" ];
        };

        mcp-servers.settings.servers.google-workspace.url = "http://localhost:${toString port}/mcp";
      };
  };
}
