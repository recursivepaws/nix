{ config, ... }: {
  imports = [ ./portal.nix ];
  programs = {
    niri = {
      settings = {
        environment = {
          QT_QPA_PLATFORMTHEME = "gtk3";
          QT_QPA_PLATFORMTHEME_QT6 = "gtk3";
        };
        spawn-at-startup = [
          { command = [ "bash" "-c" "wl-paste --watch cliphist store &" ]; }
          { command = [ "bash" "-c" "1password --silent" ]; }
        ];
        layer-rules = [{
          matches = [{ namespace = "^notifications$"; }];
          block-out-from = "screencast";
        }];
        window-rules = [
          {
            matches = [
              { app-id = "^signal$"; }
              { app-id = "^org\\.telegram\\.desktop$"; }
              { app-id = "^1Password$"; }
              { app-id = "^whatsie$"; }
            ];
            block-out-from = "screencast";
          }
          {
            matches = [
              { app-id = "^Pinentry-gtk$"; }
              { app-id = "^xdg-desktop-portal-gtk"; }
              {
                app-id = "^hyprpolkitagent$";
              }
              # { = "^whatsie$"; }
            ];
            open-floating = true;
          }
          {
            geometry-corner-radius = {
              bottom-left = 15.0;
              bottom-right = 15.0;
              top-left = 15.0;
              top-right = 15.0;
            };
            clip-to-geometry = true;
          }
        ];
        debug.honor-xdg-activation-with-invalid-serial = [ ];
        binds = with config.lib.niri.actions;
          let
            sh = spawn "sh" "-c";
            ns = x: sh ("noctalia-shell ipc call " + x);
          in {
            "Mod+Q".action = spawn "kitty";
            "Mod+P".action = ns "sessionMenu toggle";
            "Mod+X".action = ns "launcher toggle";
            "Mod+Shift+X".action = quit;
            "Mod+F".action = maximize-column;
            "Mod+Shift+F".action = fullscreen-window;
            "Mod+C".action = close-window;
            "Mod+E".action = spawn "thunar";
            "Mod+Ctrl+S".action = ns "niri screenshot";

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
            "XF86AudioRaiseVolume".action = ns "volume increase";
            "XF86AudioLowerVolume".action = ns "volume decrease";
            "XF86AudioMute".action = ns "volume muteOutput";
          };
      };
    };

  };
}
