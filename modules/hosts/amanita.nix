{ den, ... }:
{
  den.aspects.amanita = {
    den.aspects.work.includes = [ den.provides.primary-user ];

    nixos =
      { pkgs, ... }:
      {
        networking.hostName = "amanita";
        boot.loader.grub = {
          enable = true;
          efiSupport = false;
          device = "/dev/nvme0n1";
        };
        boot.loader.systemd-boot.enable = false;
        boot.loader.efi.canTouchEfiVariables = true;
        boot.loader.efi.efiSysMountPoint = "/boot";

        hardware.system76.enableAll = true;

        environment.systemPackages = with pkgs; [
          lm_sensors
          scrcpy
          #neovim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
          networkmanager
          sccache
          wayland
          wget

          # TODO: fix nvim building without these
          gcc
          gnumake
          # TODO: end

          mold
          cargo
          go
          uv
          python314
          delta
          v4l-utils
          eza
          bat
          zoxide
          guvcview
          ffmpeg-full
          SDL2
          yasm
          nasm
          tree
          gawk
          bc
          htop
          xprop
          clang-tools
        ];
        environment.sessionVariables = {
          NIXOS_OZONE_WL = "1";
          GTK_USE_PORTAL = "1";
        };
        environment.pathsToLink = [
          "/share/applications"
          "/share/xdg-desktop-portal"
          "/share/gtksourceview-4"
        ];

        programs = {
          coolercontrol.enable = true;
          chromium.enable = true;
          fzf = {
            fuzzyCompletion = true;
            # enable = true;
            # enableZshIntegration = true;
            # defaultCommand = "fd --hidden --strip-cwd-prefix --exclude .git";
          };
          _1password.enable = true;
          _1password-gui = {
            enable = true;
            polkitPolicyOwners = [
              "vera"
              "work"
            ];
          };
        };

        services = {
          openssh = {
            enable = true;
            settings = {
              PermitRootLogin = "no";
            };
          };
          pipewire.enable = true;
          avahi.enable = true;
        };
        # enabled in the niri flake aspect
        # security = { polkit.enable = true; };
      };

    # provides.to-users.includes = with den.aspects; [
    #   hightouch
    # ];
  };
}
