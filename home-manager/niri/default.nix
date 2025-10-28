{ inputs, ... }: {
  imports = [
    inputs.niri.homeModules.niri
    inputs.dankMaterialShell.homeModules.dankMaterialShell.default
    inputs.dankMaterialShell.homeModules.dankMaterialShell.niri
  ];

  programs = {
    dankMaterialShell = { enable = true; };

    niri = {
      settings = { spawn-at-startup = [{ command = [ "dms run -d" ]; }]; };
    };
  };
}
