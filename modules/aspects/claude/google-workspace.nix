{
  inputs,
  den,
  lib,
  ...
}:
{
  flake-file.inputs = {
    google-workspace-mcp = {
      url = "github:taylorwilsdon/google_workspace_mcp/v2.2.1";
      flake = false;
    };
    # Build the server from its uv.lock: it needs fastmcp 4 and mcp 2, which nixpkgs lacks.
    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        pyproject-nix.follows = "pyproject-nix";
      };
    };
    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        pyproject-nix.follows = "pyproject-nix";
        uv2nix.follows = "uv2nix";
      };
    };
  };

  # Pulled in by claude.nix for every user; mcp-servers options come from there.
  den.aspects.google-workspace =
    { user, ... }:
    {
      # One OAuth client per user: work and personal Google accounts live in different Cloud projects.
      # Declared here rather than in ragenix.nix so a host only carries the secrets of users it has.
      nixos = lib.optionalAttrs (user != null) {
        age.secrets."google-oauth-client-${user.userName}" = {
          file = ../../../secrets + "/google-oauth-client-${user.userName}.age";
          owner = user.userName;
          mode = "0400";
        };
      };

      homeManager =
        {
          pkgs,
          lib,
          config,
          ...
        }:
        let
          port = 8000;
          clientSecret = "/run/agenix/google-oauth-client-${config.home.username}";
          workspace = inputs.uv2nix.lib.workspace.loadWorkspace {
            workspaceRoot = inputs.google-workspace-mcp;
          };
          pythonSet =
            (pkgs.callPackage inputs.pyproject-nix.build.packages { python = pkgs.python313; }).overrideScope
              (
                lib.composeManyExtensions [
                  inputs.pyproject-build-systems.overlays.default
                  (workspace.mkPyprojectOverlay { sourcePreference = "wheel"; })
                ]
              );
          # The disk extra backs the OAuth proxy store selected below.
          workspace-mcp = pythonSet.mkVirtualEnv "workspace-mcp-${pythonSet.workspace-mcp.version}" {
            workspace-mcp = [ "disk" ];
          };
        in
        {
          # HTTP transport with MCP OAuth 2.1, so Claude Code signs in via /mcp like the hosted servers.
          # Upstream calls stdio the legacy path: no MCP-level auth, Google login per tool call.
          systemd.user.services.workspace-mcp = {
            Unit.Description = "Google Workspace MCP server";
            Service = {
              ExecStart = "${workspace-mcp}/bin/workspace-mcp --transport streamable-http";
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
