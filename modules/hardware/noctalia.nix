{
  flake.modules.nixos.noctalia = { pkgs, inputs, ... }: {
    environment.systemPackages = with pkgs; [
      inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
      gpu-screen-recorder-gtk
    ];

    programs.gpu-screen-recorder.enable = true;
  };
}
