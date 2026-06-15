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

  den.aspects.amanita.nixos = { pkgs, ... }: {
    hardware.graphics = {
      enable = true;
      extraPackages = with pkgs; [ intel-media-driver ];
    };
    environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";
    environment.systemPackages = [ pkgs.libva-utils ];
  };
}
