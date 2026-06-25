{
  den.aspects.hericium.nixos = { pkgs, ... }: {
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    environment.systemPackages = with pkgs; [
      mesa-demos
      vulkan-tools
      vulkan-headers
      clinfo
      libdrm
      libvdpau
      vdpauinfo
      driversi686Linux.vdpauinfo
      libva
      libva-utils
      wayland-utils
    ];
  };

  den.aspects.amanita.nixos = { pkgs, config, ... }: {
    hardware.graphics = {
      enable = true;
      extraPackages = with pkgs; [ intel-media-driver ];
    };
    environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";
    environment.systemPackages = [ pkgs.libva-utils ];

    # Proprietary NVIDIA in PRIME offload mode so the Intel iGPU drives the display while the dGPU powers up on demand.
    # powerManagement restores VRAM across suspend, which nouveau failed to do when its GSP firmware locked up on resume.
    services.xserver.videoDrivers = [ "nvidia" ];
    hardware.nvidia = {
      open = true;
      modesetting.enable = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      powerManagement.enable = true;
      powerManagement.finegrained = true;
      prime = {
        offload.enable = true;
        offload.enableOffloadCmd = true;
        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:1:0:0";
      };
    };
  };
}
