{ pkgs, inputs, ... }: {
  # import the home manager module
  imports = [ inputs.noctalia.homeModules.default ];

  programs.noctalia-shell.systemd.enable = true;

  # configure options
  programs.noctalia-shell = {
    enable = true;
    # package = null;
    settings = {
      # configure noctalia here
      bar = {
        density = "compact";
        position = "right";
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
      colorSchemes.predefinedScheme = "Monochrome";
      # general = {
      #   avatarImage = "/home/drfoobar/.face";
      #   radiusRatio = 0.2;
      # };
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
      };
      version = 1;
    };
  };
}

