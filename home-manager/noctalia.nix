{ pkgs, inputs, ... }:
let
  defaultSource = "https://github.com/noctalia-dev/noctalia-plugins";
  plugins = [
    "pomodoro"
    "todo"
    "unicode-picker"
    "clipper"
    "screen-recorder"
    "privacy-indicator"
  ];
in {
  imports = [ inputs.noctalia.homeModules.default ];

  xdg.configFile."noctalia/colorschemes/Oxocarbon/Oxocarbon.json".source =
    pkgs.fetchurl {
      url =
        "https://raw.githubusercontent.com/noctalia-dev/noctalia-colorschemes/79829c121516de5ffcb5ab62f6dc178c8534a34a/Oxocarbon/Oxocarbon.json";
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
          center = [{
            hideUnoccupied = false;
            id = "Workspace";
            labelMode = "none";
          }];
          right = map (name: { id = "plugin:" + name; }) plugins;
        };
      };
      wallpaper = { directory = ../assets/fungi; };
      colorSchemes.predefinedScheme = "Oxocarbon";
      general = {
        avatarImage = ../assets/recursivepaws.png;
        radiusRatio = 0.2;
      };
      location = {
        monthBeforeDay = false;
        name = "Washington, DC";
      };
    };
    plugins = {
      sources = [{
        enabled = true;
        name = "Official Noctalia Plugins";
        url = defaultSource;
      }];
      states = let
        mkPlugin = name: {
          name = name;
          value = {
            enabled = true;
            sourceUrl = defaultSource;
          };
        };
      in builtins.listToAttrs (map mkPlugin plugins);
      version = 1;
    };
  };
}

