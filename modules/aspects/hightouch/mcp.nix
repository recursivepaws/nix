{ den, ... }:
{
  den.aspects.hightouch = {
    homeManager =
      {
        pkgs,
        lib,
        user,
        ...
      }:
      let
        # Run npx from $HOME so project configs can't interfere.
        npxFromHome = pkgs.writeShellScript "npx-from-home" ''
          cd "$HOME"
          exec ${pkgs.nodejs}/bin/npx "$@"
        '';
      in
      # optionalAttrs, not mkIf: mcp-servers options only exist when claude imports mcp-servers-nix.
      lib.optionalAttrs (user.hasAspect den.aspects.claude) {
        mcp-servers.settings.servers = {
          circleci = {
            command = "${npxFromHome}";
            args = [
              "-y"
              "@circleci/mcp-server-circleci@latest"
            ];
            env = {
              CIRCLECI_TOKEN = "\${CIRCLECI_TOKEN}";
            };
          };
          snowflake = {
            url = "\${SNOWFLAKE_MCP_URL}";
            headers = {
              Authorization = "Bearer \${SNOWFLAKE_PAT}";
            };
          };
          datadog = {
            command = "${npxFromHome}";
            args = [
              "-y"
              "@winor30/mcp-server-datadog"
            ];
            env = {
              DATADOG_API_KEY = "\${DATADOG_API_KEY}";
              DATADOG_APP_KEY = "\${DATADOG_APP_KEY}";
            };
          };
          slack = {
            command = "${npxFromHome}";
            args = [
              "-y"
              "slack-mcp-server@latest"
              "--transport"
              "stdio"
            ];
            env = {
              SLACK_MCP_XOXC_TOKEN = "\${SLACK_MCP_XOXC_TOKEN}";
              SLACK_MCP_XOXD_TOKEN = "\${SLACK_MCP_XOXD_TOKEN}";
            };
          };
          hightouch-internal = {
            command = "${npxFromHome}";
            args = [
              "-y"
              "@hightouchio/internal-mcp@latest"
            ];
            env = {
              HIGHTOUCH_API_KEY = "\${HIGHTOUCH_API_KEY}";
            };
          };
        };
      };
  };
}
