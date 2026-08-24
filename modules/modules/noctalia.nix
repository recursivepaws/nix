{ inputs, ... }:
let
  disable-screenrec-hardware = final: prev: {
    wl-screenrec = prev.wl-screenrec.overrideAttrs (old: {
      nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ final.makeWrapper ];
      postInstall = (old.postInstall or "") + ''
        wrapProgram $out/bin/wl-screenrec \
          --add-flags "--no-hw"
      '';
    });
  };
in
{
  flake-file.inputs.noctalia = {
    # still in alpha
    # url = "github:noctalia-dev/noctalia-shell";
    url = "github:noctalia-dev/noctalia/legacy-v4";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.noctalia = {
    nixos =
      {
        host,
        pkgs,
        lib,
        ...
      }:
      {
        # My lame w6400 does not support hardware encoding
        nixpkgs.overlays = lib.mkIf (host.name == "hericium") [ disable-screenrec-hardware ];

        environment.systemPackages = with pkgs; [
          inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default

          # sync wallpapers from r2
          rclone

          # start deps for clipper
          cliphist
          wl-clipboard
          # end deps for clipper

          # start deps for screen-toolkit
          grim
          slurp
          wl-clipboard
          tesseract
          imagemagick
          zbar
          curl
          translate-shell

          wl-screenrec
          # wf-recorder

          ffmpeg
          gifski
          jq
          # end deps for screen-toolkit
        ];

        programs.gpu-screen-recorder.enable = true;

        # Wallpapers live in a central location shared by all users
        systemd.tmpfiles.rules = [ "d /var/lib/wallpapers 0755 root root -" ];

        # One-shot sync service
        systemd.services.sync-wallpapers = {
          description = "Sync wallpapers from R2";
          serviceConfig = {
            Type = "oneshot";
            ExecStart = pkgs.writeShellScript "sync-wallpapers" ''
              source /run/agenix/secrets
              ${pkgs.rclone}/bin/rclone sync \
              :s3:wallpapers \
              /var/lib/wallpapers \
              --s3-provider Cloudflare \
              --s3-endpoint https://df83fe57e6346adcb5072f073702daea.r2.cloudflarestorage.com \
              --s3-access-key-id "$S3_ACCESS_KEY_ID" \
              --s3-secret-access-key "$S3_SECRET_ACCESS_KEY" \
              --s3-no-check-bucket
            '';
          };
        };
        # Run sync on boot + once a day
        systemd.timers.sync-wallpapers = {
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnBootSec = "2min";
            OnCalendar = "daily";
          };
        };

        # Laptop-specific services
        services = lib.mkIf (host.name == "amanita") {
          upower.enable = true;
        };
      };

    homeManager =
      {
        pkgs,
        lib,
        config,
        user,
        ...
      }:
      let
        defaultSource = "https://github.com/noctalia-dev/noctalia-plugins";
        isWork = user.userName == "work";
        plugins = [
          "timer"
          "pomodoro"
          "todo"
          "unicode-picker"
          "clipper"
          "privacy-indicator"
          "catwalk"
          "screen-toolkit"
        ]
        ++ lib.optionals isWork [
          "kubectl-ctx"
          "tailscale"
          "mini-docker"
          "github-feed"
        ];
      in
      {
        imports = [ inputs.noctalia.homeModules.default ];

        xdg.configFile."noctalia/colorschemes/Oxocarbon/Oxocarbon.json".source = pkgs.fetchurl {
          url = "https://raw.githubusercontent.com/noctalia-dev/noctalia-colorschemes/79829c121516de5ffcb5ab62f6dc178c8534a34a/Oxocarbon/Oxocarbon.json";
          hash = "sha256-/MyJJcQhxFSf8oku6DZmbqA2SZmoQru8e/IMo9vSZ7c=";
        };

        programs.noctalia-shell = {
          enable = true;
          systemd.enable = false;
          settings = {
            bar = {
              density = "spacious";
              position = "top";
              showCapsule = true;
              widgets = {
                left = [
                  {
                    id = "ControlCenter";
                    useDistroLogo = true;
                  }
                  {
                    id = "microphone";
                    displayMode = "alwaysShow";
                  }
                  {
                    id = "Volume";
                    displayMode = "alwaysShow";
                  }
                  {
                    id = "Clock";
                    formatHorizontal = "ddd MMM dd [ hh:mm AP ]";
                    useMonospacedFont = true;
                    usePrimaryColor = true;
                  }
                  {
                    id = "NotificationHistory";
                    showUnreadBadge = true;
                  }
                  {
                    id = "SystemMonitor";
                    compactMode = true;
                    showCpuTemp = true;
                    showCpuUsage = true;
                    showDiskUsage = true;
                    showLoadAverage = true;
                    showMemoryAsPercent = true;
                    showMemoryUsage = true;
                    showNetworkStats = true;
                    useMonospaceFont = true;
                  }
                  {
                    id = "Tray";
                    hidePassive = true;
                    drawerEnabled = true;
                  }
                ];
                center = [
                  {
                    hideUnoccupied = false;
                    id = "Workspace";
                    labelMode = "none";
                  }
                ];
                right = map (name: { id = "plugin:" + name; }) plugins ++ [
                  {
                    id = "Battery";
                    displayMode = "icon-always";
                    hideIfNotDetected = true;
                  }
                ];
              };
            };
            wallpaper = {
              directory = "/var/lib/wallpapers";
              automationEnabled = true;
              wallPaperChangeMode = "random";
              # Change wallpaper every two hours
              randomIntervalSec = 60 * 60 * 2;
              transitionType = [ "pixelate" ];
            };
            colorSchemes.predefinedScheme = "Oxocarbon";
            sessionMenu.powerOptions = [
              {
                action = "lock";
                enabled = true;
                keybind = "1";
              }
              {
                action = "suspend";
                enabled = true;
                keybind = "2";
              }
              {
                action = "hibernate";
                enabled = false;
                # keybind = "3";
              }
              {
                action = "reboot";
                enabled = true;
                keybind = "3";
              }
              {
                action = "logout";
                enabled = true;
                keybind = "4";
              }
              {
                action = "shutdown";
                enabled = true;
                keybind = "5";
              }
              {
                action = "rebootToUefi";
                enabled = true;
                keybind = "6";
              }
            ];
            general = {
              avatarImage = user.profilePicture;
              radiusRatio = 0.2;
            };
            location = {
              monthBeforeDay = false;
              name = "New York, NY";
              use12hourFormat = true;
              useFahrenheit = true;
            };
            appLauncher = {
              enableClipboardHistory = true;
            };
          };
          plugins = {
            sources = [
              {
                enabled = true;
                name = "Official Noctalia Plugins";
                url = defaultSource;
              }
            ];
            states =
              let
                mkPlugin = name: {
                  name = name;
                  value = {
                    enabled = true;
                    sourceUrl = defaultSource;
                  };
                };
              in
              builtins.listToAttrs (map mkPlugin plugins);
            version = 1;
          };
          pluginSettings = {
            pomodoro = {
              workDuration = 30;
              playSound = true;
            };
          };
        };

        home.activation = {
          # screen-toolkit has no IPC to annotate an existing image, so patch an
          # annotateFile(path) command plus fit-to-screen scaling into the installed plugin (written for v1.3.3)
          noctaliaScreenToolkitAnnotateFile = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
            plugin_dir="${config.xdg.configHome}/noctalia/plugins/screen-toolkit"
            annotate_patch=${./noctalia-screen-toolkit-annotate-file.patch}

            if [ -f "$plugin_dir/Main.qml" ] && ! grep -q annotateFileProc "$plugin_dir/Main.qml"; then
              if ${pkgs.patch}/bin/patch -p1 -d "$plugin_dir" --silent --dry-run < "$annotate_patch" > /dev/null 2>&1; then
                run ${pkgs.patch}/bin/patch -p1 -d "$plugin_dir" --silent < "$annotate_patch"
              else
                echo "warning: screen-toolkit annotate-file patch no longer applies, skipping" >&2
              fi
            fi
          '';
        }
        // lib.optionalAttrs isWork {
          noctaliaGithubFeedToken = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
            token_file="/run/agenix/github.token"
            settings_file="${config.xdg.configHome}/noctalia/plugins/github-feed/settings.json"

            if [ -r "$token_file" ]; then
              token=$(< "$token_file")
              run mkdir -p "$(dirname "$settings_file")"
              ${pkgs.jq}/bin/jq -n --arg token "$token" '{username: "recursivepaws", defaultTab: 1, token: $token}' > "$settings_file"
            fi
          '';
        };
      };
  };
}
