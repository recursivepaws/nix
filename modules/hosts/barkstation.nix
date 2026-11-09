{ inputs, ... }:
let
  # 1Password ssh key (same as den.default.user) plus the key used to install from ampulex.
  adminKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIINY5xZYRlbxjdw4N47VADFRSU3EeSI3Yze97F8cWGLS"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE9lAEWNh0SQ9SFyPIjp0/uhLutGleznTHwkoDlhc9LG vera@ampulex"
  ];

  nfs = share: {
    device = "MeowStation.local:/volume1/${share}";
    fsType = "nfs";
    # Mount on first access so boot never waits on the NAS.
    options = [
      "x-systemd.automount"
      "x-systemd.idle-timeout=600"
      "noauto"
      "nofail"
      "_netdev"
      "hard"
    ];
  };
in
{
  flake-file.inputs.disko = {
    url = "github:nix-community/disko";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.barkstation.nixos =
    { lib, modulesPath, ... }:
    {
      imports = [
        (modulesPath + "/installer/scan/not-detected.nix")
        inputs.disko.nixosModules.disko
      ];

      # Lowercase to match the flake attr (`rebuild` runs `nix run .#$(hostname)`); mDNS is case-insensitive.
      networking.hostName = "barkstation";
      system.stateVersion = lib.mkForce "26.11";

      # Intel N100 mini PC, SATA SSD.
      boot.initrd.availableKernelModules = [
        "xhci_pci"
        "ahci"
        "usb_storage"
        "sd_mod"
      ];
      boot.kernelModules = [ "kvm-intel" ];
      hardware.cpu.intel.updateMicrocode = true;
      nixpkgs.hostPlatform = "x86_64-linux";

      boot.loader.systemd-boot = {
        enable = true;
        configurationLimit = 10;
      };

      disko.devices.disk.main = {
        device = "/dev/disk/by-id/ata-512GB_SSD_MQ21B38007908";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };

      fileSystems."/mnt/data" = nfs "data";
      fileSystems."/mnt/immich" = nfs "immich";

      # Same uid as on Debian (and Synology's first user) so restored files and NFS perms line up.
      users.users.vera = {
        uid = 1026;
        extraGroups = [ "docker" ];
        openssh.authorizedKeys.keys = adminKeys;
      };
      # Headless: no password is ever set for vera, so sudo can't prompt.
      security.sudo.wheelNeedsPassword = false;
      users.users.root.openssh.authorizedKeys.keys = adminKeys;
      services.openssh.settings.PermitRootLogin = lib.mkForce "prohibit-password";

      virtualisation.docker = {
        enable = true;
        autoPrune.enable = true;
      };

      # Portainer runs the compose stacks; its data volume (restored from backup) holds them.
      virtualisation.oci-containers = {
        backend = "docker";
        containers.portainer = {
          image = "portainer/portainer-ce:lts";
          ports = [
            "8000:8000"
            "9443:9443"
          ];
          volumes = [
            "/var/run/docker.sock:/var/run/docker.sock"
            "portainer_data:/data"
          ];
        };
      };

      # Announce barkstation.local; NixOS avahi only resolves by default.
      services.avahi.publish = {
        enable = true;
        addresses = true;
      };

      # Docker-published ports bypass this firewall; only jellyfin uses host networking.
      networking.firewall = {
        allowedTCPPorts = [ 8096 ];
        allowedUDPPorts = [
          1900
          7359
        ];
      };
    };
}
