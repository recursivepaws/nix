{ config, ... }: {
  # Establish the network secret file
  age.secrets.network = { file = ../secrets/network.age; };
  networking.networkmanager = {
    enable = true;
    wifi.backend = "iwd";
    ensureProfiles = {
      # Use the network secret file to load the encrypted environment variables
      environmentFiles = [ config.age.secrets.network.path ];
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
}
