{
  den.aspects.audio-fix = {
    nixos =
      { pkgs, ... }:
      let
        # Analog and Intel HDMI audio share one ALSA card.
        # Only one output profile is active at a time.
        # Force HDMI when a display is connected.
        monitor-audio-switch = pkgs.writeShellScript "monitor-audio-switch" ''
          set -u
          export XDG_RUNTIME_DIR=/run/user/1001
          card=alsa_card.pci-0000_00_1f.3
          connected=0
          for status in /sys/class/drm/card*-*/status; do
            conn=''${status%/status}
            base=''${conn##*/}
            case "$base" in *eDP*) continue ;; esac
            cardname=''${base%%-*}
            target=$(${pkgs.coreutils}/bin/readlink -f "/sys/class/drm/$cardname/device/driver" 2>/dev/null)
            drv=''${target##*/}
            [ "$drv" = i915 ] || continue
            [ "$(< "$status")" = connected ] && connected=1
          done
          if [ "$connected" = 1 ]; then
            profile=output:hdmi-stereo+input:analog-stereo
          else
            profile=output:analog-stereo+input:analog-stereo
          fi
          ${pkgs.pulseaudio}/bin/pactl set-card-profile "$card" "$profile" || true
        '';
      in
      {
        services.udev.extraRules = ''
          ACTION=="change", SUBSYSTEM=="drm", RUN+="${pkgs.systemd}/bin/systemctl start --no-block monitor-audio-switch.service"
        '';

        systemd.services.monitor-audio-switch = {
          description = "Switch audio profile when a display is (un)plugged";
          serviceConfig = {
            Type = "oneshot";
            ExecStartPre = "${pkgs.coreutils}/bin/sleep 1";
            ExecStart = monitor-audio-switch;
          };
        };

        systemd.user.services.monitor-audio-switch = {
          description = "Set audio profile for connected displays at login";
          after = [ "pipewire-pulse.service" ];
          wants = [ "pipewire-pulse.service" ];
          wantedBy = [ "default.target" ];
          serviceConfig = {
            Type = "oneshot";
            ExecStartPre = "${pkgs.coreutils}/bin/sleep 2";
            ExecStart = monitor-audio-switch;
          };
        };
      };
  };
}
