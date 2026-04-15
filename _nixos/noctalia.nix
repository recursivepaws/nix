{ pkgs, inputs, ... }: {
  # imports = [ inputs.noctalia.nixosModules.default ];
  # install package
  environment.systemPackages = with pkgs; [
    inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
    gpu-screen-recorder-gtk
  ];

  programs.gpu-screen-recorder.enable = true;

  # services.noctalia-shell.enable = true;
}
