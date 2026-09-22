{ inputs, ... }:
{
  # nixpkgs follows would change hashes and miss cachix
  flake-file.inputs.noctalia.url = "github:noctalia-dev/noctalia";

  den.aspects.noctalia = {
    nixos =
      {
        host,
        pkgs,
        lib,
        ...
      }:
      {
        environment.systemPackages = with pkgs; [
          inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default

          # sync wallpapers from r2
          rclone
        ];

        # used by the official screen-recorder plugin
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
        services = lib.mkIf (host.name == "amanita" || host.name == "ampulex") {
          upower.enable = true;
        };
      };

    homeManager =
      {
        pkgs,
        user,
        ...
      }:
      {
        imports = [ inputs.noctalia.homeModules.default ];

        programs.noctalia = {
          enable = true;
          package = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
          systemd.enable = false;

          # Same JSON format v4 called a color scheme
          customPalettes.Oxocarbon = pkgs.fetchurl {
            url = "https://raw.githubusercontent.com/noctalia-dev/noctalia-colorschemes/79829c121516de5ffcb5ab62f6dc178c8534a34a/Oxocarbon/Oxocarbon.json";
            hash = "sha256-/MyJJcQhxFSf8oku6DZmbqA2SZmoQru8e/IMo9vSZ7c=";
          };

          settings = {
            shell = {
              avatar_path = user.profilePicture;
              corner_radius_scale = 0.2;
              time_format = "{:%-I:%M %p}";
              session.actions = [
                {
                  action = "lock";
                  shortcut = "1";
                }
                {
                  action = "suspend";
                  shortcut = "2";
                }
                {
                  action = "reboot";
                  shortcut = "3";
                }
                {
                  action = "logout";
                  shortcut = "4";
                }
                {
                  action = "shutdown";
                  shortcut = "5";
                }
                {
                  action = "command";
                  label = "Reboot to UEFI";
                  command = "systemctl reboot --firmware-setup";
                  shortcut = "6";
                }
              ];
            };

            theme = {
              mode = "dark";
              source = "custom";
              custom_palette = "Oxocarbon";
            };

            wallpaper = {
              directory = "/var/lib/wallpapers";
              transition = [ "honeycomb" ];
              automation = {
                enabled = true;
                # Change wallpaper every two hours
                interval_seconds = 60 * 60 * 2;
                order = "random";
              };
            };

            location.address = "New York, NY";

            bar.main = {
              position = "top";
              capsule = true;
              start = [
                "control-center"
                "mic"
                "volume"
                "clock"
                "notifications"
                "sysmon-cpu"
                "sysmon-cputemp"
                "sysmon-ram"
                "sysmon-disk"
                "sysmon-rx"
                "sysmon-tx"
                "tray"
              ];
              center = [ "workspaces" ];
              end = [
                "privacy"
                "battery"
              ];
            };

            widget = {
              control-center = {
                custom_image = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                custom_image_colorize = true;
              };
              mic = {
                type = "volume";
                device = "input";
              };
              clock.format = "{:%a %b %d [ %I:%M %p ]}";
              tray.drawer = true;
              workspaces.show_labels = false;
              battery.show_label = false;
              sysmon-cpu = {
                type = "sysmon";
                stat = "cpu_usage";
              };
              sysmon-cputemp = {
                type = "sysmon";
                stat = "cpu_temp";
              };
              sysmon-ram = {
                type = "sysmon";
                stat = "ram_pct";
              };
              sysmon-disk = {
                type = "sysmon";
                stat = "disk_used_pct";
              };
              sysmon-rx = {
                type = "sysmon";
                stat = "net_rx";
              };
              sysmon-tx = {
                type = "sysmon";
                stat = "net_tx";
              };
            };
          };
        };
      };
  };
}
