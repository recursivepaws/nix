{ config, lib, ... }: {
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
        # screenshot-path =
        #   "~/Pictures/Screenshots/Screenshot from %YYYY-%m-%d %H-%M-%S.png";
        layout = {
          border = {
            enable = true;
            width = 4;
            # Oxocarbon primary
            active = { color = "#33b1ff"; };
          };
          focus-ring = { enable = false; };
          tab-indicator = {
            enable = true;
            width = 8;
            gap = 4;
            # place-within-column = true;
            length = { total-proportion = 0.8; };
            corner-radius = 8;
            active = { color = "#33b1ff"; };
            inactive = { color = "#161616"; };
          };
        };
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
            "Mod+Ctrl+S".action.spawn = [
              "bash"
              "-c"
              ''
                set -e; grim -t ppm -g "$(slurp -o -d -F monospace)" - | satty --filename - --copy-command=wl-copy --annotation-size-factor 2.0 --output-filename="${
                  lib.escapeShellArg
                  config.programs.niri.settings.screenshot-path
                }" --actions-on-enter="save-to-clipboard,exit" --brush-smooth-history-size=5 --disable-notifications''
            ];

            "Mod+S".action = toggle-column-tabbed-display;

            "Mod+V".action = center-column;

            "Mod+Shift+V".action = toggle-window-floating;

            # "Mod+Ctrl+S".action = screenshot;

            "Mod+H".action = focus-column-left;
            "Mod+J".action = focus-window-down;
            "Mod+K".action = focus-window-up;
            "Mod+L".action = focus-column-right;

            "Mod+Ctrl+H".action = move-column-left;
            "Mod+Ctrl+J".action = move-window-down;
            "Mod+Ctrl+K".action = move-window-up;
            "Mod+Ctrl+L".action = move-column-right;

            "Mod+Minus".action = set-column-width "-10%";
            "Mod+Shift+Minus".action = set-window-height "-10%";
            "Mod+Shift+Plus".action = set-window-height "+10%";
            "Mod+Plus".action = set-column-width "+10%";

            "Mod+Shift+P".action = power-off-monitors;

            "Mod+W".action = toggle-overview;

            # "Mod+Shift+H".action = set-column-width "-10%";
            # "Mod+Shift+J".action = set-window-height "-10%";
            # "Mod+Shift+K".action = set-window-height "+10%";
            # "Mod+Shift+L".action = set-column-width "+10%";
            # Mod+Minus { set-column-width "-10%"; }
            # Mod+Equal { set-column-width "+10%"; }
            #
            # // Finer height adjustments when in column with other windows.
            # Mod+Shift+Minus { set-window-height "-10%"; }
            # Mod+Shift+Equal { set-window-height "+10%"; }

            # "Mod+Minus".action = set-column-width "-10%";
            # "Mod+".action = set-column-width "-10%";

            "Mod+BracketLeft".action = consume-or-expel-window-left;
            "Mod+BracketRight".action = consume-or-expel-window-right;
            "Mod+Slash".action = consume-window-into-column;
            "Mod+Backslash".action = expel-window-from-column;
            # // The following binds move the focused window in and out of a column.
            # // If the window is alone, they will consume it into the nearby column to the side.
            # // If the window is already in a column, they will expel it out.
            # Mod+BracketLeft  { consume-or-expel-window-left; }
            # Mod+BracketRight { consume-or-expel-window-right; }
            #
            # // Consume one window from the right to the bottom of the focused column.
            # Mod+Comma  { consume-window-into-column; }
            # // Expel the bottom window from the focused column to the right.
            # Mod+Period { expel-window-from-column; }

            # "Mod+".action = move-column-right;

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
