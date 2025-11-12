{ config, pkgs, ... }: {
  # Establish the network secret file
  # age.secrets.network = { file = ../secrets/network.age; };
  networking.networkmanager = {
    enable = true;
    wifi.backend = "iwd";
    ensureProfiles = {
      # Use the startup secret file to load the encrypted environment variables
      environmentFiles = [ config.age.secrets.startup.path ];
      profiles = {
        ziggurat = {
          connection = {
            type = "wifi";
            id = "ziggurat";
            autoconnect = true;
          };
          wifi = {
            mode = "infrastructure";
            ssid = "ziggurat";
          };
          wifi-security = {
            key-mgmt = "wpa-psk";
            # Use the environment variables from agenix to set the wifi password
            psk = "$ZIGGURAT_PASSWORD";
          };
          ipv4 = {
            method = "manual";
            addresses = "192.168.1.191/24";
            gateway = "192.168.1.1";
            dns = "8.8.8.8";
          };
          ipv6 = {
            addr-gen-mode = "stable-privacy";
            method = "auto";
          };
        };
      };
    };
  };

  # Avahi enables us to use mDNS so we can use hostnames instead of raw IP addresses
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    nssmdns6 = true;
  };

  environment.systemPackages = with pkgs; [ nfs-utils ];
  boot = { supportedFilesystems = [ "nfs" "nfs4" "ext4" ]; };
  systemd.services."mnt-data.automount".reloadIfChanged = false;

  fileSystems."/mnt/data" = {
    device = "MeowStation.local:/volume1/data";
    fsType = "nfs";
    options = [
      # Version
      "nfsvers=4"

      # Prevent lockups
      "bg"
      "noatime"
      "retry=0"
      "soft"
      "timeo=100"

      # Better performance.
      "nconnect=16"

      # Dont autostart
      "_netdev"
      "noauto"
      "x-systemd.automount"
      "x-systemd.idle-timeout=10min"
      "x-systemd.mount-timeout=10"

      # Require network to start
      "x-systemd.requires=network-online.target"

      # Show in the file manager
      "x-gvfs-icon=folder-remote"
      "x-gvfs-show"
      "x-gvfs-symbolic-icon=folder-remote-symbolic"
    ];
  };
}
