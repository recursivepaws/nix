{ den, ... }:
{
  den.aspects.ampulex = {
    den.aspects.vera.includes = [ den.provides.primary-user ];
    includes = [ den.aspects.audio-fix ];

    nixos =
      { pkgs, ... }:
      let
        # Noctalia ignores logind's Lock signal, verified live, so lock via noctalia IPC directly.
        # Uses busctl get-property only, no root, runs as vera.
        lockSession = pkgs.writeShellScript "lock-session" ''
          set -euo pipefail
          uid=$(id -u vera)
          wayland_display=$(cd "/run/user/$uid" 2>/dev/null && ls wayland-*.lock 2>/dev/null | head -1 | sed 's/\.lock$//')
          [ -n "$wayland_display" ] || exit 0
          export XDG_RUNTIME_DIR="/run/user/$uid" WAYLAND_DISPLAY="$wayland_display"
          /run/current-system/sw/bin/noctalia-shell ipc call lockScreen lock
          /run/current-system/sw/bin/noctalia-shell ipc call monitors off
        '';
      in
      {
        networking.hostName = "ampulex";
        boot.loader.grub = {
          enable = true;
          efiSupport = true;
          device = "nodev";
        };
        boot.loader.systemd-boot.enable = false;
        boot.loader.efi.canTouchEfiVariables = true;
        boot.loader.efi.efiSysMountPoint = "/boot";

        programs.chromium.enable = true;

        services.fwupd.enable = true;
        # enabled in niri flake aspect
        # security = { polkit.enable = true; };

        # HandleLidSwitch=lock is no-op here; logind only drives idle-suspend.
        services.logind.settings.Login = {
          HandleLidSwitch = "ignore";
          IdleAction = "suspend";
          IdleActionSec = "5min";
        };

        # Locks on lid close, skipped when docked.
        # Polls LidClosed (not busctl monitor), no root needed.
        systemd.services.lid-close-lock-watch = {
          description = "Lock when the lid closes";
          wantedBy = [ "multi-user.target" ];
          after = [ "systemd-logind.service" ];
          serviceConfig = {
            Restart = "always";
            User = "vera";
            ExecStart = pkgs.writeShellScript "lid-close-lock-watch" ''
              set -euo pipefail
              prev=false
              while true; do
                cur=$(${pkgs.systemd}/bin/busctl get-property org.freedesktop.login1 \
                  /org/freedesktop/login1 org.freedesktop.login1.Manager LidClosed | cut -d' ' -f2)
                if [ "$cur" = true ] && [ "$prev" = false ]; then
                  docked=$(${pkgs.systemd}/bin/busctl get-property org.freedesktop.login1 \
                    /org/freedesktop/login1 org.freedesktop.login1.Manager Docked | cut -d' ' -f2)
                  [ "$docked" = true ] || ${lockSession}
                fi
                prev=$cur
                sleep 1
              done
            '';
          };
        };

        # Safety net: lock before any suspend, even idle-timeout suspend with lid open.
        systemd.services.lock-before-sleep = {
          description = "Lock session before suspend/hibernate";
          wantedBy = [ "sleep.target" ];
          before = [ "sleep.target" ];
          serviceConfig = {
            User = "vera";
            ExecStart = "${lockSession}";
          };
        };
      };

    provides.to-users.includes = with den.aspects; [
      amd
      crypto
      davinci
      varnam
      gaming
    ];
  };
}
