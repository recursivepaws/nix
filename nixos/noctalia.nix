{ pkgs, inputs, ... }: {
  # imports = [ inputs.noctalia.nixosModules.default ];
  # install package
  environment.systemPackages = with pkgs; [
    inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
    gpu-screen-recorder
  ];

  # services.noctalia-shell.enable = true;
}
