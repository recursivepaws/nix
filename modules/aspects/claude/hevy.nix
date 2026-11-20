{ den, ... }:
{
  # Pulled in by claude.nix for the vera user; mcp-servers options and npxFromHome come from there.
  den.aspects.hevy = {
    homeManager =
      { npxFromHome, ... }:
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
