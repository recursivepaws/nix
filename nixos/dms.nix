{ inputs, ... }: {
  imports = [
    inputs.dankMaterialShell.nixosModules.greeter
    inputs.dankMaterialShell.nixosModules.dankMaterialShell
  ];

  programs.dankMaterialShell = {
    enable = true;
    systemd = {
      enable = true;
      restartIfChanged = true;
    };
    enableColorPicker = true;
    # plugins = with inputs; {
    #   DankPomodoroTimer.src = "${dms-official-plugins}/DankPomodoroTimer";
    # };
  };

  systemd.user.services.niri-flake-polkit.enable = false;
}
