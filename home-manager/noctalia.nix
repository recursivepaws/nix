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
        # density = "compact";
        position = "top";
        showCapsule = false;
        widgets = {
          left = [
            {
              id = "ControlCenter";
              useDistroLogo = true;
            }
            { id = "Network"; }
            { id = "Bluetooth"; }
          ];
          center = [{
            hideUnoccupied = false;
            id = "Workspace";
            labelMode = "none";
          }];
          right = [
            {
              alwaysShowPercentage = false;
              id = "Battery";
              warningThreshold = 30;
            }
            {
              formatHorizontal = "HH:mm";
              formatVertical = "HH mm";
              id = "Clock";
              useMonospacedFont = true;
              usePrimaryColor = true;
            }
          ];
        };
      };
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
      states = {
        catwalk = {
          enabled = true;
          sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
        };
        pomodoro = {
          enabled = true;
          sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
        };
        todo = {
          enabled = true;
          sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
        };
        # unicode-picker = {
        #   enabled = true;
        #   sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
        # };
        clipper = {
          enabled = true;
          sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
        };
      };
      version = 1;
    };
  };
}

