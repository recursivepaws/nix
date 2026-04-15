{
  den.aspects.gpu = {

    nixos = { pkgs, ... }: {
      hardware.graphics = {
        enable = true;
        enable32Bit = true;

        ## amdvlk: an open-source Vulkan driver from AMD
        # extraPackages = [ pkgs.amdvlk ];
        # extraPackages32 = [ pkgs.driversi686Linux.amdvlk ];
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
  };
}
