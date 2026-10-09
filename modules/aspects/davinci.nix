{ den, inputs, ... }:
{
  flake-file.inputs = {
    # DaVinci Resolve MCP server (plain server.py against Resolve's scripting API).
    davinci-resolve-mcp = {
      url = "github:samuelgursky/davinci-resolve-mcp";
      flake = false;
    };
  };

  den.aspects.davinci =
    {
      user ? null,
      ...
    }:
    {
      homeManager =
        { pkgs, lib, config, ... }:
        {
          # Resolve bundles Qt5 without a wayland platform plugin, so it dies
          # silently under the session-wide QT_QPA_PLATFORM=wayland set in niri.nix.
          # https://github.com/NixOS/nixpkgs/issues/341634
          home.packages = [
            (pkgs.symlinkJoin {
              name = "davinci-resolve-studio-xcb";
              paths = [ pkgs.davinci-resolve-studio ];
              nativeBuildInputs = [ pkgs.makeWrapper ];
              postBuild = ''
                for bin in $out/bin/*; do
                  wrapProgram "$bin" --set QT_QPA_PLATFORM xcb
                done
              '';
            })
          ];
        }
        # optionalAttrs, not mkIf: mcp-servers options only exist when claude imports mcp-servers-nix.
        // lib.optionalAttrs (user != null && user.hasAspect den.aspects.claude) {
          mcp-servers.settings.servers.davinci-resolve = {
            command = "${pkgs.python3.withPackages (ps: [ ps.mcp ])}/bin/python";
            args = [ "${inputs.davinci-resolve-mcp}/src/server.py" ];
            env = {
              RESOLVE_SCRIPT_API = "${pkgs.davinci-resolve-studio.davinci}/Developer/Scripting";
              RESOLVE_SCRIPT_LIB = "${pkgs.davinci-resolve-studio.davinci}/libs/Fusion/fusionscript.so";
              # server.py logs beside itself, which is the read-only store here.
              # It dies at import without this.
              RESOLVE_MCP_LOG_FILE = "${config.xdg.cacheHome}/davinci-resolve-mcp/server.log";
              # fusionscript.so needs libs that exist only in Resolve's FHS sandbox.
              # usr/lib there is an absolute symlink, so point at lib64 directly.
              LD_LIBRARY_PATH = "${pkgs.davinci-resolve-studio.fhsenv}/usr/lib64";
            };
          };
        };
    };
}
