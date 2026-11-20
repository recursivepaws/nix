{ den, ... }:
{
  # Pulled in by claude.nix for the vera user; mcp-servers options and npxFromHome come from there.
  den.aspects.tailscale-mcp = {
    homeManager =
      { npxFromHome, ... }:
      {
        # Community server (no official one); pinned since the key can delete and deauthorize devices.
        mcp-servers.settings.servers.tailscale = {
          command = "${npxFromHome}";
          args = [
            "-y"
            "@hexsleeves/tailscale-mcp-server@1.3.4"
          ];
          env = {
            TAILSCALE_API_KEY = "\${TAILSCALE_API_KEY}";
            # "-" is the API's alias for the key's own tailnet.
            TAILSCALE_TAILNET = "-";
          };
        };
      };
  };
}
