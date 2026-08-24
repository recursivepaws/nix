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

    # The NVIDIA driver never releases freed buffers, so niri holds ~1 GiB of VRAM instead of ~100 MiB.
    # INFO: https://github.com/niri-wm/niri/wiki/Nvidia
    environment.etc."nvidia/nvidia-application-profiles-rc.d/50-limit-free-buffer-pool-in-wayland-compositors.json".text =
      builtins.toJSON {
        rules = [
          {
            pattern = {
              feature = "procname";
              matches = "niri";
            };
            profile = "Limit Free Buffer Pool On Wayland Compositors";
          }
        ];
        profiles = [
          {
            name = "Limit Free Buffer Pool On Wayland Compositors";
            settings = [
              {
                key = "GLVidHeapReuseRatio";
                value = 0;
              }
            ];
          }
        ];
      };

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
