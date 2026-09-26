{ inputs, ... }:
{
  flake-file.inputs.nixos-hardware.url = "github:NixOS/nixos-hardware/master";

  den.aspects.ampulex.nixos =
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
        inputs.nixos-hardware.nixosModules.framework-amd-ai-300-series
      ];

      boot.initrd.availableKernelModules = [
        "nvme"
        "xhci_pci"
        "thunderbolt"
        "usb_storage"
        "sd_mod"
      ];
      boot.initrd.kernelModules = [ ];
      boot.kernelModules = [ "kvm-amd" ];

      # Strix Point display mitigations. nixos-hardware applies these to the 16-inch
      # AI 300 sibling but not the 13-inch, whose module only disables PSR (0x10).
      # 0x610 is Framework's own published Strix Point value: PSR (0x10) + PSR
      # Selective Update (0x200) + Panel Replay (0x400). All three engage on static
      # content, which is when the flicker shows up. 0x410 left PSR-SU enabled.
      # abmlevel=0 disables Adaptive Backlight Management, which modulates backlight
      # from frame content and pumps brightness on an idle screen — the driver
      # default (-1) leaves it on.
      # sg_display=0 stops scanout out of system RAM, which this host leans on
      # heavily with a 512 MiB VRAM carveout driving a 2880x1920 panel.
      # mkAfter keeps these last on the cmdline, so they win over the 0x10 above.
      boot.kernelParams = lib.mkAfter [
        "amdgpu.dcdebugmask=0x610"
        "amdgpu.abmlevel=0"
        "amdgpu.sg_display=0"
      ];

      # The shared amd aspect turns on overdrive with ppfeaturemask=0xffffffff for
      # hericium's dGPU. nixpkgs documents that value as unstable and flicker-prone,
      # and this host is an APU with no use for overclocking.
      hardware.amdgpu.overdrive.enable = lib.mkForce false;
      boot.extraModulePackages = [ ];
      fileSystems."/" = {
        device = "/dev/disk/by-uuid/ca53fb37-947b-45a9-88a6-73d34a088871";
        fsType = "ext4";
      };

      fileSystems."/boot" = {
        device = "/dev/disk/by-uuid/EEB9-7392";
        fsType = "vfat";
        options = [
          "fmask=0077"
          "dmask=0077"
        ];
      };

      fileSystems."/home" = {
        device = "/dev/mapper/luks-2c18397f-da32-4e92-8566-cbb0dbfc2c9b";
        fsType = "ext4";
        neededForBoot = true;
      };

      boot.initrd.luks.devices."luks-2c18397f-da32-4e92-8566-cbb0dbfc2c9b".device =
        "/dev/disk/by-uuid/2c18397f-da32-4e92-8566-cbb0dbfc2c9b";

      fileSystems."/nix" = {
        device = "/home/nix";
        fsType = "none";
        options = [ "bind" ];
      };

      swapDevices = [ ];

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    };

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
        neededForBoot = true;
      };

      boot.initrd.luks.devices."luks-969ef9cc-02b9-44d2-908e-d333ac2e4c5f".device =
        "/dev/disk/by-uuid/969ef9cc-02b9-44d2-908e-d333ac2e4c5f";

      fileSystems."/nix" = {
        device = "/home/nix";
        fsType = "none";
        options = [ "bind" ];
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
        # bind source for /nix — must be mounted in stage 1
        neededForBoot = true;
      };

      fileSystems."/nix" = {
        device = "/home/nix";
        fsType = "none";
        options = [ "bind" ];
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
