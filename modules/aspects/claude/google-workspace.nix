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
        # HACK: needs fastmcp 4 and mcp 2, neither in nixpkgs yet. uv syncs the repo's uv.lock into a
        # per-user venv on first launch; main.py runs in place since setuptools can't write egg-info into the store.
        workspace-mcp = pkgs.writeShellScript "workspace-mcp" ''
          export UV_PROJECT_ENVIRONMENT="${config.xdg.cacheHome}/workspace-mcp"
          export UV_PYTHON=${pkgs.python3}/bin/python3
          export UV_PYTHON_DOWNLOADS=never
          ${pkgs.uv}/bin/uv sync --frozen --no-dev --no-install-project --project ${inputs.google-workspace-mcp} >&2
          exec "$UV_PROJECT_ENVIRONMENT/bin/python" ${inputs.google-workspace-mcp}/main.py "$@"
        '';
      in
      {
        mcp-servers.settings.servers.google-workspace = {
          command = "${workspace-mcp}";
          # Per-user OAuth client file, next to the tokens the server keeps under ~/.google_workspace_mcp.
          env.GOOGLE_CLIENT_SECRET_PATH = "${config.home.homeDirectory}/.google_workspace_mcp/client_secret.json";
        };
      };
  };
}
