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
      # earlyoom kills the largest process at 5% free, which is Resolve mid-render.
      nixos.services.earlyoom.extraArgs = [
        "--avoid"
        "^resolve$"
      ];

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

          # Linux Resolve cannot encode AAC either, so MP4 exports carry FLAC/PCM without this.
          # DOCS: https://github.com/Toxblh/davinci-linux-aac-codec
          aac-encoder-plugin = pkgs.stdenv.mkDerivation (final: {
            pname = "aac-encoder-plugin";
            version = "1.0.1";
            src = pkgs.fetchFromGitHub {
              owner = "Toxblh";
              repo = "davinci-linux-aac-codec";
              tag = "v${final.version}";
              hash = "sha256-NVNxmUFNwZ3hzlyi3QVENXhfPICAAP3M4s6QEgWsP/g=";
            };
            buildInputs = [ pkgs.ffmpeg-full ];
            # Upstream Makefile hardcodes Fedora include paths, so compile directly.
            buildPhase = ''
              $CXX -shared -fPIC -O2 -std=c++11 -Iinclude -Iwrapper plugin.cpp audio_encoder.cpp wrapper/host_api.cpp -lavcodec -lavutil -o aac_encoder_plugin.dvcp
            '';
            installPhase = ''
              install -D aac_encoder_plugin.dvcp $out/IOPlugins/aac_encoder_plugin.dvcp.bundle/Contents/Linux-x86-64/aac_encoder_plugin.dvcp
            '';
          });

          # Resolve ignores QT_SCALE_FACTOR; its only UI scale is <DisplayScale> in config.user.xml.
          # Follow the largest niri output scale so each host gets its own value.
          # HACK: Resolve accepts 100/150/200 only, so a 1.25 output yields an invalid 125.
          displayScale = builtins.floor (
            100
            * lib.foldl' lib.max 1.0 (
              map (o: if (o.scale or null) == null then 1.0 else o.scale) (
                lib.attrValues (lib.attrByPath [ "programs" "niri" "settings" "outputs" ] { } config)
              )
            )
          );

          # Text+ scans SystemFonts: (/usr/share/fonts), not fontconfig, and the sandbox /usr has no fonts.
          # Expose the NixOS fontDir there so no per-user Path Map edit is needed.
          fonts = pkgs.linkFarm "resolve-fonts" {
            "share/fonts" = "/run/current-system/sw/share/X11/fonts";
          };

          # <install>/IOPlugins and the sandbox /usr are both read-only store paths, so overlay at launch instead of rebuilding the 14 GiB tree.
          # WARN: overlays must precede nixpkgs' license/Extras binds or they shadow them.
          davinci-resolve-studio = pkgs.davinci-resolve-studio.override (old: {
            buildFHSEnv =
              args:
              let
                pkg = pkgs.buildFHSEnv (
                  args
                  // {
                    extraBwrapArgs = [
                      "--overlay-src ${ffmpeg-encoder-plugin}"
                      "--overlay-src ${aac-encoder-plugin}"
                      "--overlay-src ${args.passthru.davinci}"
                      "--ro-overlay ${args.passthru.davinci}"
                      "--overlay-src ${fonts}/share"
                      "--overlay-src ${pkg.fhsenv}/usr/share"
                      "--ro-overlay /usr/share"
                    ]
                    ++ args.extraBwrapArgs;
                  }
                );
              in
              pkg;
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
              # Resolve rewrites config.user.xml on exit, so pin DisplayScale right before each launch.
              # Its Qt multiplies the X cursor by that scale and niri scales X11 surfaces again, so divide the cursor back out.
              postBuild = ''
                for bin in $out/bin/*; do
                  wrapProgram "$bin" --set QT_QPA_PLATFORM xcb --run '
                    f="$HOME/.local/share/DaVinciResolve/configs/config.user.xml"
                    [ -f "$f" ] && ${pkgs.gnused}/bin/sed -i "s#<DisplayScale>[0-9]*</DisplayScale>#<DisplayScale>${toString displayScale}</DisplayScale>#" "$f"
                    case "''${XCURSOR_SIZE:-24}" in *[!0-9]*) ;; *) export XCURSOR_SIZE=$(( ''${XCURSOR_SIZE:-24} * 100 / ${toString displayScale} )) ;; esac
                  '
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
