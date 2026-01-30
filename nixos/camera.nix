{ pkgs, ... }:
let
  camera = {
    vendor = "054c";
    id = "0ac2";
  };

  cameraSyncScript = pkgs.writeShellApplication {
    name = "camera-sync";
    runtimeInputs = with pkgs; [
      exfat
      util-linux # mountpoint, mount
      coreutils # tee, id, readlink, cat, basename, seq, mkdir, sleep
      cifs-utils # mount.cifs
      systemd # udevadm
      gnugrep # grep
      bash # bash
      immich-cli # immich
    ];
    text = builtins.readFile ../scripts/camera-sync.sh;
  };
in {
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="${camera.vendor}", ATTR{idProduct}=="${camera.id}", TAG+="systemd", ENV{SYSTEMD_WANTS}="camera-sync.service"'';
  systemd.services.camera-sync = {
    description = "Sync files from Camera server to Immich";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart =
        "${cameraSyncScript}/bin/camera-sync ${camera.vendor} ${camera.id}";
      User = "root"; # Needs root for mounting
      # Allow access to the agenix secret
      SupplementaryGroups = [ "keys" ];
    };
  };
}

