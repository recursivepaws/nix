{ den, ... }:
{
  # Pulled in by claude.nix for the vera user; mcp-servers options come from there.
  den.aspects.hevy = {
    homeManager =
      { pkgs, ... }:
      let
        # Run npx from $HOME so project configs can't interfere.
        npxFromHome = pkgs.writeShellScript "npx-from-home" ''
          cd "$HOME"
          exec ${pkgs.nodejs}/bin/npx "$@"
        '';
      in
      {
        # HACK: upstream is an nx/pnpm monorepo and its tarball leaves deps unbundled.
        # So npx rather than a store-pinned build; deps land in ~/.npm on first launch.
        mcp-servers.settings.servers.hevy = {
          command = "${npxFromHome}";
          args = [
            "-y"
            "hevy-mcp@6.1.22"
          ];
          env = {
            HEVY_API_KEY = "\${HEVY_API_KEY}";
            HEVY_MCP_TELEMETRY = "0";
          };
        };
      };
  };
}
