{
  den.default.nixos =
    { config, pkgs, ... }:
    {
      networking = {
        networkmanager = {
          enable = true;
        };
      };

      # Avahi enables us to use mDNS so we can use hostnames instead of raw IP addresses
      services = {
        avahi = {
          enable = true;
          nssmdns4 = true;
          nssmdns6 = true;
        };
      };

      environment.systemPackages = with pkgs; [ nfs-utils ];
      boot = {
        supportedFilesystems = [
          "nfs"
          "nfs4"
          "ext4"
        ];
      };
    };
}
