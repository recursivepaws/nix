{ inputs, config, ... }: {
  imports = [
    inputs.niri.homeModules.niri
    inputs.dankMaterialShell.homeModules.dankMaterialShell.default
    inputs.dankMaterialShell.homeModules.dankMaterialShell.niri
  ];

  programs = {
    dankMaterialShell = { enable = true; };

    niri = {
      settings = {
        spawn-at-startup = [{ command = [ "dms run -d" ]; }];
        binds = with config.lib.niri.actions;
          let sh = spawn "sh" "-c";
          in {
            "Mod+Q".action = spawn "kitty";
            # "Mod+E".action.spawn = "thunar";
            "Mod+X".action = sh "dms ipc call spotlight toggle";
          };
      };
    };
  };
}
