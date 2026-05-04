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
    url = "github:noctalia-dev/noctalia-shell";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.noctalia = {
    nixos =
      { pkgs, ... }:
      {
        # My lame w6400 does not support hardware encoding
        nixpkgs.overlays = [ disable-screenrec-hardware ];

        environment.systemPackages = with pkgs; [
          inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default

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
      };

    homeManager =
      { pkgs, ... }:
      let
        defaultSource = "https://github.com/noctalia-dev/noctalia-plugins";
        plugins = [
          "timer"
          "pomodoro"
          "todo"
          "unicode-picker"
          "clipper"
          "privacy-indicator"
          "catwalk"
          "screen-toolkit"
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
          systemd.enable = true;
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
                    formatHorizontal = "HH:mm";
                    formatVertical = "HH mm";
                    id = "Clock";
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
                right = map (name: { id = "plugin:" + name; }) plugins;
              };
            };
            wallpaper = {
              directory = ../../assets/fungi;
              automationEnabled = true;
              wallPaperChangeMode = "random";
              randomIntervalSec = 300;
              transitionType = [ "pixelate" ];
            };
            colorSchemes.predefinedScheme = "Oxocarbon";
            general = {
              avatarImage = ../../assets/recursivepaws.png;
              radiusRatio = 0.2;
            };
            location = {
              monthBeforeDay = false;
              name = "Washington, DC";
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
      };
  };
}
