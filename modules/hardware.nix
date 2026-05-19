{
  den.aspects.amanita.nixos =
    {
      config,
      lib,
      pkgs,
      modulesPath,
      ...
    }:
    {
      imports = [
        (modulesPath + "/installer/scan/not-detected.nix")
      ];

      boot.initrd.availableKernelModules = [
        "xhci_pci"
        "thunderbolt"
        "nvme"
        "usb_storage"
        "sd_mod"
        "sdhci_pci"
      ];
      boot.initrd.kernelModules = [ ];
      boot.kernelModules = [ "kvm-intel" ];
      boot.extraModulePackages = [ ];

      fileSystems."/" = {
        device = "/dev/disk/by-uuid/cf6936e2-1a04-4804-904f-1dda643c1f28";
        fsType = "ext4";
      };

      fileSystems."/boot" = {
        device = "/dev/disk/by-uuid/F0C5-02F7";
        fsType = "vfat";
        options = [
          "fmask=0077"
          "dmask=0077"
        ];
      };

      fileSystems."/home" = {
        device = "/dev/disk/by-uuid/9c0eeeff-5e69-4bbb-b04d-5c78e77b4405";
        fsType = "ext4";
      };

      boot.initrd.luks.devices."luks-969ef9cc-02b9-44d2-908e-d333ac2e4c5f".device =
        "/dev/disk/by-uuid/969ef9cc-02b9-44d2-908e-d333ac2e4c5f";

      fileSystems."/nix" = {
        device = "/dev/disk/by-uuid/48aadf9c-872b-408b-9c96-aceb5863ec58";
        fsType = "ext4";
      };

      swapDevices = [ ];

      # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
      # (the default) this is the recommended approach. When using systemd-networkd it's
      # still possible to use this option, but it's recommended to use it in conjunction
      # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
      networking.useDHCP = lib.mkDefault true;
      # networking.interfaces.eno0.useDHCP = lib.mkDefault true;
      # networking.interfaces.wlp0s20f3.useDHCP = lib.mkDefault true;

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    };

  den.aspects.hericium.nixos =
    {
      config,
      lib,
      pkgs,
      modulesPath,
      ...
    }:
    {
      imports = [
        (modulesPath + "/installer/scan/not-detected.nix")
      ];

      boot.initrd.availableKernelModules = [
        "xhci_pci"
        "ahci"
        "nvme"
        "usb_storage"
        "sd_mod"
      ];
      boot.initrd.kernelModules = [ ];
      boot.kernelModules = [ "kvm-amd" ];
      boot.extraModulePackages = [ ];

      fileSystems."/" = {
        device = "/dev/disk/by-uuid/886248d2-8a06-4457-947e-7d8d52485f78";
        fsType = "ext4";
      };

      fileSystems."/boot" = {
        device = "/dev/disk/by-uuid/21C2-6AED";
        fsType = "vfat";
        options = [
          "fmask=0022"
          "dmask=0022"
        ];
      };

      fileSystems."/home" = {
        device = "/dev/disk/by-uuid/e2821909-3c68-4b9d-9836-bcf3f6ded2a7";
        fsType = "ext4";
      };

      fileSystems."/nix" = {
        device = "/dev/disk/by-uuid/e38a5854-1fda-4a51-a6cf-5b3b25d362c3";
        fsType = "ext4";
      };

      boot.initrd.luks.devices = {
        "sda-crypt" = {
          device = "/dev/disk/by-uuid/d610c823-2623-4c18-b85f-d0c6027bdeff";
          keyFile = "/ssd-keyfile";
          preLVM = true;
        };
        "sdb-crypt" = {
          device = "/dev/disk/by-uuid/e2f21827-04e9-4338-a640-308dee6f086b";
          keyFile = "/ssd-keyfile";
          preLVM = true;
        };
      };

      boot.initrd.secrets = {
        "/ssd-keyfile" = /ssd-keyfile;
      };

      services.lvm.enable = true;

      environment.etc."lvm/lvm.conf".text = ''
        devices {
          allow_mixed_block_sizes = 1
        }
      '';

      fileSystems."/run/media/vera/storage" = {
        device = "/dev/disk/by-uuid/70721713-667d-4df8-b651-adfe9c3d5236";
        fsType = "ext4";
        options = [ "defaults" ];
      };

      swapDevices = [ ];

      # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
      # (the default) this is the recommended approach. When using systemd-networkd it's
      # still possible to use this option, but it's recommended to use it in conjunction
      # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
      networking.useDHCP = lib.mkDefault true;
      # networking.interfaces.enp6s0.useDHCP = lib.mkDefault true;
      # networking.interfaces.wlp7s0.useDHCP = lib.mkDefault true;

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    };

}
