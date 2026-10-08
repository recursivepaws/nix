{ den, ... }:
{
  den.aspects.ampulex = {
    den.aspects.vera.includes = [ den.provides.primary-user ];

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
          /run/current-system/sw/bin/noctalia msg session lock
          /run/current-system/sw/bin/noctalia msg dpms-off
        '';
      in
      {
        networking.hostName = "ampulex";
        boot.loader.grub = {
          enable = true;
          efiSupport = true;
          device = "nodev";
        };
        programs.chromium.enable = true;

        services.upower.enable = true;
        services.fwupd.enable = true;
        # enabled in niri flake aspect
        # security = { polkit.enable = true; };

        # HandleLidSwitch=lock is no-op here; logind only drives idle-suspend.
        services.logind.settings.Login = {
          HandleLidSwitch = "suspend";
          IdleAction = "lock";
          IdleActionSec = "5min";
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
    ];

    provides.to-users.homeManager =
      { lib, user, ... }:
      lib.optionalAttrs (user.hasAspect den.aspects.niri) {
        programs.niri.settings.outputs."eDP-1".scale = 1.5;
      };
  };
}
