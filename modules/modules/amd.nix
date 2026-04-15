{
  den.aspects.amd = {
    nixos = { pkgs, ... }: {

      config = {
        hardware = {
          amdgpu = {
            initrd.enable = true;
            opencl.enable = true;
            overdrive = {
              enable = true;
              ppfeaturemask = "0xffffffff";
            };
          };
        };

        # Useful userland tools for AMD GPUs
        environment.systemPackages = with pkgs; [
          radeontop
          rocmPackages.rocm-smi
        ];

        # Fix some ROCm related issues specific to NixOS
        systemd.tmpfiles.rules = let
          rocmEnv = pkgs.symlinkJoin {
            name = "rocm-combined";
            paths = with pkgs.rocmPackages; [ rocblas hipblas clr ];
          };
        in [ "L+    /opt/rocm   -    -    -     -    ${rocmEnv}" ];
      };
    };
  };
}
