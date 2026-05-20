{
  den.default.nixos =
    { ... }:
    {
      hardware.enableAllFirmware = true;
      hardware.bluetooth = {
        enable = true;
        powerOnBoot = true;
        settings = {
          General = {
            Experimental = true;
            FastConnectable = true;
          };
          Policy = {
            AutoEnable = true;
          };
        };
      };

      # Disable USB autosuspend for btusb — the Intel Legacy ROM 2.x adapter
      # (0aa7) firmware crashes when it tries to resume from suspend during an
      # active SCO link, which is what kills the adapter mid-call.
      boot.extraModprobeConfig = ''
        options btusb enable_autosuspend=0
      '';

      # Auto-recover the bluetooth service when the adapter disappears.
      # The Intel adapter can enter a USB-dead state after a failed reset;
      # this restarts bluetoothd so it re-probes once the device comes back
      # (e.g. after a reboot), rather than staying broken until next login.
      systemd.services.bluetooth = {
        serviceConfig = {
          Restart = "on-failure";
          RestartSec = "5s";
        };
      };
    };
}
