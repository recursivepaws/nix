{
  den.aspects.ipod = {
    nixos = { pkgs, ... }:
      let
        ipod = {
          vendor = "05ac";
          id = "1209";
        };

        ipodSyncScript = pkgs.writeShellApplication {
          name = "ipod-sync";
          runtimeInputs = with pkgs; [
            util-linux # mountpoint, mount
            coreutils # tee, id, readlink, cat, basename, seq, mkdir, sleep
            cifs-utils # mount.cifs
            rsync # rsync
            systemd # udevadm
            gnugrep # grep
            bash # bash
            zenity # progress
            sudo # sudo
          ];
          text = builtins.readFile ../../scripts/ipod-sync.sh;
        };
      in {
        services.udev.extraRules = ''
          ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="${ipod.vendor}", ATTR{idProduct}=="${ipod.id}", TAG+="systemd", ENV{SYSTEMD_WANTS}="ipod-sync.service"'';
        systemd.services.ipod-sync = {
          description = "Sync files from SMB server to iPod";
          environment = {
            DISPLAY = ":0";
            # XAUTHORITY = "/home/vera/.Xauthority";
          };
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];
          serviceConfig = {
            Type = "oneshot";
            ExecStart =
              "${ipodSyncScript}/bin/ipod-sync ${ipod.vendor} ${ipod.id}";
            User = "root"; # Needs root for mounting
            # Allow access to the agenix secret
            SupplementaryGroups = [ "keys" ];
          };
        };
      };
  };
}

