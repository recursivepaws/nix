{ inputs, config, ... }: {
  imports = [
    inputs.niri.homeModules.niri
    inputs.dankMaterialShell.homeModules.dankMaterialShell.default
    inputs.dankMaterialShell.homeModules.dankMaterialShell.niri
    ./portal.nix
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
        environment = {
          QT_QPA_PLATFORMTHEME = "gtk3";
          QT_QPA_PLATFORMTHEME_QT6 = "gtk3";
        };
        spawn-at-startup = [
          { command = [ "dms" "run" "-d" ]; }
          { command = [ "bash" "-c" "wl-paste --watch cliphist store &" ]; }
        ];
        window-rules = [{
          matches = [
            { app-id = "^signal$"; }
            { app-id = "^org.telegram.desktop$"; }
            { app-id = "^1Password$"; }
          ];
          block-out-from = "screencast";
        }];
        binds = with config.lib.niri.actions;
          let sh = spawn "sh" "-c";
          in {
            "Mod+Q".action = spawn "kitty";
            "Mod+X".action = sh "dms ipc call spotlight toggle";
            "Mod+Shift+X".action = quit;
            "Mod+F".action = maximize-column;
            "Mod+Shift+F".action = fullscreen-window;
            "Mod+C".action = close-window;
            "Mod+E".action = spawn "thunar";
            "Mod+Ctrl+S".action.screenshot = [ ];

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

            # Media controls
            "XF86AudioPlay".action = sh "playerctl play-pause";
            "XF86AudioNext".action = sh "playerctl next";
            "XF86AudioPrev".action = sh "playerctl previous";
            "XF86AudioRaiseVolume".action = sh "dms ipc call audio increment 3";
            "XF86AudioLowerVolume".action = sh "dms ipc call audio decrement 3";
            "XF86AudioMute".action = sh "dms ipc call audio mute";
          };
      };
    };
  };
}
