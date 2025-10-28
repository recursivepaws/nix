{ inputs, config, ... }: {
  imports = [
    inputs.niri.homeModules.niri
    inputs.dankMaterialShell.homeModules.dankMaterialShell.default
    inputs.dankMaterialShell.homeModules.dankMaterialShell.niri
  ];

  programs = {
    dankMaterialShell = {
      enable = true;
      plugins = with inputs; {
        DankPomodoroTimer.src = "${dms-official-plugins}/DankPomodoroTimer";
      };
    };

    niri = {
      settings = {
        spawn-at-startup = [{ command = [ "dms" "run" "-d" ]; }];
        binds = with config.lib.niri.actions;
          let sh = spawn "sh" "-c";
          in {
            "Mod+Q".action = spawn "kitty";
            # "Mod+E".action.spawn = "thunar";
            "Mod+X".action = sh "dms ipc call spotlight toggle";
            "Mod+Shift+X".action = quit;
            "Mod+F".action = maximize-column;
            "Mod+Shift+F".action = fullscreen-window;
            "Mod+C".action = close-window;

            "Mod+H".action = focus-column-left;
            "Mod+J".action = focus-window-down;
            "Mod+K".action = focus-window-up;
            "Mod+L".action = focus-column-right;

            "Mod+Ctrl+H".action = move-column-left;
            "Mod+Ctrl+J".action = move-window-down;
            "Mod+Ctrl+K".action = move-window-up;
            "Mod+Ctrl+L".action = move-column-right;

            # "Mod+Ctrl+S".action = screenshot;

            "Mod+Page_Down".action = focus-workspace-down;
            "Mod+Page_Up".action = focus-workspace-up;
            "Mod+Ctrl+Page_Down".action = move-column-to-workspace-down;
            "Mod+Ctrl+Page_Up".action = move-column-to-workspace-up;
          };
      };
    };
  };
}
