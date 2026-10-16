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

      # The Intel Legacy ROM 2.x adapter (0aa7) crashes resuming from suspend during an active SCO link, which is what kills it mid-call.
      boot.extraModprobeConfig = ''
        options btusb enable_autosuspend=0
      '';

      # The Intel adapter can go USB-dead after a failed reset.
      # Restarting bluetoothd lets it re-probe when the device comes back, instead of staying broken until next login.
      systemd.services.bluetooth = {
        serviceConfig = {
          Restart = "on-failure";
          RestartSec = "5s";
        };
      };
    };
}
