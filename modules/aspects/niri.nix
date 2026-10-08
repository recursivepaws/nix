{ inputs, ... }:
{
  flake-file.inputs.niri-flake = {
    url = "github:sodiboo/niri-flake";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.niri = {
    nixos =
      { pkgs, lib, ... }:
      {
        imports = with inputs; [ niri-flake.nixosModules.niri ];
        nixpkgs.overlays = with inputs; [ niri-flake.overlays.niri ];

        environment.systemPackages = with pkgs; [
          xwayland-satellite
          gnome-text-editor
          gnome-system-monitor
          gnome-control-center
          gnome-tweaks
        ];

        programs.niri = {
          enable = true;
          package = pkgs.niri-stable;
        };

        services.gnome.gnome-keyring.enable = true;

        # The Niri flake ships the KDE polkit agent; noctalia provides its own
        # (shell.polkit_agent), and only one can hold the session registration.
        systemd.user.services.niri-flake-polkit.enable = false;
        security.polkit.enable = true;

        xdg.portal = {
          enable = true;
          xdgOpenUsePortal = true;
          config.niri = {
            default = [
              "gtk"
              "gnome"
            ];
            "org.freedesktop.impl.portal.Access" = [ "gtk" ];
            "org.freedesktop.impl.portal.Notification" = [ "gtk" ];
            "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
            "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
            "org.freedesktop.impl.portal.ScreenCast" = [ "xdg-desktop-portal-gnome" ];
            "org.freedesktop.impl.portal.Screenshot" = [ "xdg-desktop-portal-gnome" ];
          };
          extraPortals = [
            pkgs.gnome-keyring
            pkgs.xdg-desktop-portal-gtk
            pkgs.xdg-desktop-portal-gnome
          ];
        };
      };

    homeManager =
      { pkgs, config, ... }:
      {
        home.packages = with pkgs; [
          playerctl
          qt5.qtwayland
          qt6.qtwayland
          qt5.qtbase
          adwaita-qt
          adwaita-qt6
        ];
        programs = {
          niri = {
            settings = {
              prefer-no-csd = true;
              environment = {
                QT_QPA_PLATFORMTHEME = "gtk3";
                QT_QPA_PLATFORMTHEME_QT6 = "gtk3";
                QT_QPA_PLATFORM = "wayland";
                XDG_SESSION_TYPE = "wayland";
                NIXOS_OZONE_WL = "1";
                QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
                GDK_BACKEND = "wayland";
              };
              spawn-at-startup = [
                {
                  command = [
                    "bash"
                    "-c"
                    "1password --silent"
                  ];
                }
              ];
              # screenshot-path =
              #   "~/Pictures/Screenshots/Screenshot from %YYYY-%m-%d %H-%M-%S.png";
              cursor = {
                hide-when-typing = true;
                hide-after-inactive-ms = 1000;
              };
              input = {
                touchpad.dwt = true;
                focus-follows-mouse = {
                  enable = true;
                  max-scroll-amount = "50%";
                };
                warp-mouse-to-focus = {
                  enable = true;
                  mode = "center-xy";
                };
                mouse = {
                  accel-speed = 0.1;
                  scroll-factor = {
                    horizontal = -1.0;
                    vertical = 1.0;
                  };
                };
              };
              layout = {
                empty-workspace-above-first = true;

                border = {
                  enable = true;
                  width = 4;
                  # Oxocarbon primary
                  active = {
                    color = "#33b1ff";
                  };
                };
                focus-ring = {
                  enable = false;
                };
                tab-indicator = {
                  enable = true;
                  width = 8;
                  gap = 4;
                  # place-within-column = true;
                  length = {
                    total-proportion = 0.8;
                  };
                  corner-radius = 8;
                  active = {
                    color = "#33b1ff";
                  };
                  inactive = {
                    color = "#161616";
                  };
                };
                preset-column-widths = [
                  # { proportion = 1.0 / 4.0; }
                  { proportion = 1.0 / 3.0; }
                  { proportion = 1.0 / 2.0; }
                  { proportion = 2.0 / 3.0; }
                  # { proportion = 3.0 / 4.0; }
                  { proportion = 1.0; }
                ];
                preset-window-heights = [
                  { proportion = 1.0 / 3.0; }
                  { proportion = 1.0 / 2.0; }
                  { proportion = 2.0 / 3.0; }
                  { proportion = 1.0; }
                ];
                default-column-width = {
                  proportion = 0.5;
                };
              };
              window-rules = [
                {
                  matches = [ { app-id = "^1password$"; } ];
                  block-out-from = "screencast";
                }
                {
                  matches = [
                    { app-id = "^Pinentry-gtk$"; }
                    { app-id = "^xdg-desktop-portal-gtk"; }
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
              debug = {
                honor-xdg-activation-with-invalid-serial = [ ];
              };

              binds =
                with config.lib.niri.actions;
                let
                  sh = spawn "sh" "-c";
                in
                {
                  "Mod+Shift+slash".action = show-hotkey-overlay;

                  "Mod+Shift+X".action = quit;
                  "Mod+F".action = maximize-column;
                  "Mod+Shift+F".action = fullscreen-window;
                  "Mod+C".action = close-window;
                  "Mod+S".action = toggle-column-tabbed-display;

                  "Mod+V".action = center-column;

                  "Mod+R".action = switch-preset-column-width;
                  "Mod+Shift+R".action = switch-preset-column-width-back;
                  "Mod+Ctrl+R".action = switch-preset-window-height;
                  "Mod+Ctrl+Shift+R".action = switch-preset-window-height-back;

                  "Mod+Shift+V".action = toggle-window-floating;

                  "Mod+H".action = focus-column-left;
                  "Mod+J".action = focus-window-down;
                  "Mod+K".action = focus-window-up;
                  "Mod+L".action = focus-column-right;

                  "Mod+Ctrl+H".action = move-column-left;
                  "Mod+Ctrl+J".action = move-window-down;
                  "Mod+Ctrl+K".action = move-window-up;
                  "Mod+Ctrl+L".action = move-column-right;

                  "Mod+I".action = set-column-width "-10%";
                  "Mod+O".action = set-column-width "+10%";
                  "Mod+Ctrl+I".action = set-window-height "-10%";
                  "Mod+Ctrl+O".action = set-window-height "+10%";

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
                  "XF86AudioPlay" = {
                    action = sh "playerctl play-pause";
                    allow-when-locked = true;
                  };
                  "XF86AudioNext" = {
                    action = sh "playerctl next";
                    allow-when-locked = true;
                  };
                  "XF86AudioPrev" = {
                    action = sh "playerctl previous";
                    allow-when-locked = true;
                  };
                  "XF86Display".action = power-off-monitors;
                };
            };
          };
        };
      };
  };
}
