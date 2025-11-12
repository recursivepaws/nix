{ config, pkgs, ... }: {
  # Establish the network secret file
  networking = {
    networkmanager = {
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
    firewall = {
      enable = true;
      allowedTCPPorts = [ 111 2049 4000 4001 4002 20048 ];
      allowedUDPPorts = [ 111 2049 4000 4001 4002 20048 ];
    };
  };

  systemd.tmpfiles.rules = [ "d /export/camera 0755 vera users -" ];
  # Create the bind mount (with proper handling for removable media)
  fileSystems."/export/camera" = {
    device = "/run/media/vera/3530-31321";
    fsType = "none";
    options = [
      "bind"
      "nofail" # Don't fail if camera isn't plugged in
      "x-systemd.automount"
    ];
  };

  # Avahi enables us to use mDNS so we can use hostnames instead of raw IP addresses
  services = {
    avahi = {
      enable = true;
      nssmdns4 = true;
      nssmdns6 = true;
    };
    nfs = {
      server = {
        enable = true;
        # fixed rpc.statd port; for firewall
        lockdPort = 4001;
        mountdPort = 4002;
        statdPort = 4000;
        extraNfsdConfig = "";
        exports =
          "/export/camera 192.168.1.181(ro,nohide,insecure,no_subtree_check,crossmnt,all_squash,anonuid=1000,anongid=100,fsid=1)";
      };
    };
  };

  environment.systemPackages = with pkgs; [ nfs-utils ];
  boot = { supportedFilesystems = [ "nfs" "nfs4" "ext4" ]; };
}
