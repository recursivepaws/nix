{ den, ... }:
{
  den.aspects.amanita = {
    den.aspects.work.includes = [ den.provides.primary-user ];
    includes = [ den.aspects.audio-fix ];

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

        # Default to the quiet battery profile
        # So that I dont scare my coworkers with their fancy M4 macbooks
        systemd.services.system76-power-quiet = {
          description = "Set system76-power to the quiet battery profile";
          after = [ "system76-power.service" ];
          wants = [ "system76-power.service" ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Type = "oneshot";
            # Set the quiet profile, then undo its backlight dimming (back to 100%).
            ExecStart = [
              "${pkgs.system76-power}/bin/system76-power profile battery"
              "${pkgs.brightnessctl}/bin/brightnessctl -d acpi_video0 set 100%"
            ];
          };
        };

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

          # Stop accidentally activating touchpad while i type
          udev.extraHwdb =
            let
              width = 4100;
              height = 2460;
              deadZone = 0.35;
              lo = size: toString (builtins.floor (size * deadZone / 2));
              hi = size: toString (builtins.floor (size * (1 - deadZone / 2)));
              x = "${lo width}:${hi width}";
              y = "${lo height}:${hi height}";
            in
            ''
              evdev:name:FTCS1000:00 2808:0102 Touchpad:dmi:*
               EVDEV_ABS_00=${x}
               EVDEV_ABS_01=${y}
               EVDEV_ABS_35=${x}
               EVDEV_ABS_36=${y}
            '';
        };
        # enabled in the niri flake aspect
        # security = { polkit.enable = true; };
      };

    provides.to-users.includes = with den.aspects; [
      keyboard
    ];
  };
}
