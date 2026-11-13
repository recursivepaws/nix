{
  den.aspects.ipod = {
    nixos =
      {
        pkgs,
        config,
        lib,
        user ? null,
        ...
      }:
      let
        ipod = {
          vendor = "05ac";
          id = "1209";
        };

        ipodSyncScript = pkgs.writeShellApplication {
          name = "ipod-sync";
          runtimeInputs = with pkgs; [
            util-linux # mountpoint, mount
            coreutils # tee, id, readlink, cat, basename, seq, mkdir, sleep, date
            findutils # find
            curl # syncthing REST API
            jq
            rsync
            systemd # udevadm
            gnugrep # grep
            bash
            zenity # progress dialog
            sudo
          ];
          text = builtins.readFile ../../scripts/ipod-sync.sh;
        };
      in
      lib.mkIf (user != null) {
        services.udev.extraRules = ''ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="${ipod.vendor}", ATTR{idProduct}=="${ipod.id}", TAG+="systemd", ENV{SYSTEMD_WANTS}="ipod-sync.service"'';
        systemd.services.ipod-sync = {
          description = "Sync beets library and playlists to iPod";
          restartIfChanged = false;
          environment = {
            DISPLAY = ":0";
            IPOD_USER = user.userName;
            # Same paths as syncthing.nix's configDir and folder paths.
            SYNCTHING_HOME = "/home/${user.userName}/.config/syncthing";
            MUSIC_DIR = "/home/${user.userName}/Music";
            # Always-on hub: if it agrees with us, nobody online has anything newer.
            HUB_ID = config.services.syncthing.settings.devices.barkstation.id;
          };
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${ipodSyncScript}/bin/ipod-sync ${ipod.vendor} ${ipod.id}";
            User = "root"; # Needs root for mounting
          };
        };
      };
  };
}
