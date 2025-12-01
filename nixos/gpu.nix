{ pkgs, ... }: {
  # Add amdgpu drivers and openCL for compatibility
  boot.initrd.kernelModules = [ "amdgpu" ];
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [ rocmPackages.clr.icd ];
  };
  environment.systemPackages = with pkgs; [ clinfo ];
  environment.variables = { ROC_ENABLE_PRE_VEGA = "1"; };
}
