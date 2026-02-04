{ pkgs, inputs, ... }: {
  # import the home manager module
  imports = [ inputs.noctalia.homeModules.default ];

  programs.noctalia-shell.systemd.enable = true;

  xdg.configFile."noctalia/colorschemes/Oxocarbon/Oxocarbon.json".source =
    pkgs.fetchurl {
      url =
        "https://raw.githubusercontent.com/noctalia-dev/noctalia-colorschemes/79829c121516de5ffcb5ab62f6dc178c8534a34a/Oxocarbon/Oxocarbon.json";
      hash = "sha256-/MyJJcQhxFSf8oku6DZmbqA2SZmoQru8e/IMo9vSZ7c=";
    };

  # configure options
  programs.noctalia-shell = {
    enable = true;
    # package = null;
    settings = {
      # configure noctalia here
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
            { id = "Network"; }
            { id = "Bluetooth"; }
            { id = "WallpaperSelector"; }
          ];
          center = [{
            hideUnoccupied = false;
            id = "Workspace";
            labelMode = "none";
          }];
          right = [
            {
              id = "Tray";
              hidePassive = true;
              drawerEnabled = false;
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
          ];
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
    # this may also be a string or a path to a JSON file.
    plugins = {
      sources = [{
        enabled = true;
        name = "Official Noctalia Plugins";
        url = "https://github.com/noctalia-dev/noctalia-plugins";
      }];
      states = let
        defaultSource = "https://github.com/noctalia-dev/noctalia-plugins";
        mkPlugin = name: {
          name = name;
          value = {
            enabled = true;
            sourceUrl = defaultSource;
          };
        };
        plugins = [
          "pomodoro"
          "todo"
          "unicode-picker"
          "clipper"
          "screen-recorder"
          "privacy-indicator"
        ];
      in builtins.listToAttrs (map mkPlugin plugins);
      version = 1;
    };
  };
}

