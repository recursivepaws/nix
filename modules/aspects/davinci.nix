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
        {
          pkgs,
          lib,
          config,
          ...
        }:
        let
          # Linux Studio has no H.264/H.265 encoder for AMD (NVENC/QSV only), so Deliver fails on those.
          # DOCS: https://github.com/EdvinNilsson/ffmpeg_encoder_plugin
          ffmpeg-encoder-plugin = pkgs.stdenv.mkDerivation (final: {
            pname = "ffmpeg-encoder-plugin";
            version = "1.4.0";
            src = pkgs.fetchFromGitHub {
              owner = "EdvinNilsson";
              repo = "ffmpeg_encoder_plugin";
              tag = "v${final.version}";
              hash = "sha256-q37cA1GR2+qPzrJVrAN9uOqEmQ6ehPrmZWt+v4W94OE=";
            };
            nativeBuildInputs = [ pkgs.cmake ];
            buildInputs = [
              pkgs.ffmpeg-full
              pkgs.libva
              pkgs.vulkan-headers
            ];
            installPhase = ''
              install -D ffmpeg_encoder_plugin.dvcp $out/IOPlugins/ffmpeg_encoder_plugin.dvcp.bundle/Contents/Linux-x86-64/ffmpeg_encoder_plugin.dvcp
            '';
          });

          # Resolve only scans <install>/IOPlugins, which is the read-only store.
          # Overlay the plugin in at launch instead of rebuilding the 14 GiB tree; the overlay must precede nixpkgs' license/Extras binds.
          davinci-resolve-studio = pkgs.davinci-resolve-studio.override (old: {
            buildFHSEnv =
              args:
              pkgs.buildFHSEnv (
                args
                // {
                  extraBwrapArgs = [
                    "--overlay-src ${ffmpeg-encoder-plugin}"
                    "--overlay-src ${args.passthru.davinci}"
                    "--ro-overlay ${args.passthru.davinci}"
                  ]
                  ++ args.extraBwrapArgs;
                }
              );
          });
        in
        {
          home.packages = [
            # Resolve bundles Qt5 with no wayland platform plugin, so it dies silently under the QT_QPA_PLATFORM=wayland set in niri.nix.
            # DOCS: https://github.com/NixOS/nixpkgs/issues/341634
            (pkgs.symlinkJoin {
              name = "davinci-resolve-studio-xcb";
              paths = [ davinci-resolve-studio ];
              nativeBuildInputs = [ pkgs.makeWrapper ];
              postBuild = ''
                for bin in $out/bin/*; do
                  wrapProgram "$bin" --set QT_QPA_PLATFORM xcb
                done
              '';
            })

            # Linux Resolve (free and Studio) cannot decode AAC, so phone MP4s import silent.
            # Rewrap audio to PCM and keep the video stream as is.
            (pkgs.writeShellApplication {
              name = "resolve-ingest";
              runtimeInputs = [ pkgs.ffmpeg ];
              text = ''
                for f in "$@"; do
                  ffmpeg -i "$f" -c:v copy -c:a pcm_s16le "''${f%.*}.mov"
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
