{ inputs, ... }: {
  imports = [
    inputs.dankMaterialShell.nixosModules.greeter
    inputs.dankMaterialShell.nixosModules.dankMaterialShell
  ];

  programs.dankMaterialShell = {
    greeter = {
      enable = true;
      compositor.name = "niri";
      configHome = "/home/vera";
    };
    enable = true;
    systemd = {
      enable = true;
      restartIfChanged = true;
    };
    enableColorPicker = true;
  };

  systemd.user.services.niri-flake-polkit.enable = false;
}
