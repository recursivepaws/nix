{
  den.aspects.keyboard = {
    nixos =
      { ... }:
      {
        users.groups.plugdev = { };
        services.udev.extraRules = ''
          # Rules for Oryx web flashing and live training
          KERNEL=="hidraw*", ATTRS{idVendor}=="16c0", MODE="0664", GROUP="plugdev"
          KERNEL=="hidraw*", ATTRS{idVendor}=="3297", MODE="0664", GROUP="plugdev"

          # Legacy rules for live training over webusb (Not needed for firmware v21+)
          # Rule for all ZSA keyboards
          SUBSYSTEM=="usb", ATTR{idVendor}=="3297", GROUP="plugdev"
          # Rule for the Moonlander
          SUBSYSTEM=="usb", ATTR{idVendor}=="3297", ATTR{idProduct}=="1969", GROUP="plugdev"
          # Rule for the Ergodox EZ
          SUBSYSTEM=="usb", ATTR{idVendor}=="feed", ATTR{idProduct}=="1307", GROUP="plugdev"
          # Rule for the Planck EZ
          SUBSYSTEM=="usb", ATTR{idVendor}=="feed", ATTR{idProduct}=="6060", GROUP="plugdev"

          # Wally Flashing rules for the Ergodox EZ
          ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789B]?", ENV{ID_MM_DEVICE_IGNORE}="1"
          ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789A]?", ENV{MTP_NO_PROBE}="1"
          SUBSYSTEMS=="usb", ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789ABCD]?", MODE:="0666"
          KERNEL=="ttyACM*", ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789B]?", MODE:="0666"

          # Keymapp / Wally Flashing rules for the Moonlander and Planck EZ
          SUBSYSTEMS=="usb", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="df11", MODE:="0666", SYMLINK+="stm32_dfu"
          # Keymapp Flashing rules for the Voyager
          SUBSYSTEMS=="usb", ATTRS{idVendor}=="3297", MODE:="0666", SYMLINK+="ignition_dfu"
        '';

        # Swap caps/escape on the built-in laptop keyboard only.
        # USB keyboards have real vendor:product ids and never match 0001:0001.
        services.keyd = {
          enable = true;
          keyboards.internal = {
            ids = [ "0001:0001" ];
            settings.main =
              let
                threshhold = toString 175;
              in
              {
                capslock = "esc";
                esc = "capslock";

                f = "overloadt(meta, f, ${threshhold})";
                d = "overloadt(alt, d, ${threshhold})";
                s = "overloadt(control, s, ${threshhold})";

                j = "overloadt(meta, j, ${threshhold})";
                k = "overloadt(alt, k, ${threshhold})";
                l = "overloadt(control, l, ${threshhold})";

                leftalt = "layer(symbols)";
                rightalt = "layer(functions)";
              };

            settings.symbols = {
              q = "(";
              w = ")";
              e = "{";
              r = "}";
              t = "^";
              a = "[";
              s = "]";
              d = "/";
              f = "\\";
              g = "&";
              z = "#";
              x = "@";
              c = ":";
              v = ";";
              b = "!";

              y = "$";
              u = "_";
              i = "-";
              o = "+";
              p = "=";
              h = "|";
              j = "*";
              k = "%";
              l = "'";
              ";" = "\"";
              n = "?";
              m = "~";
              "," = "`";
              "." = "<";
              "/" = ">";
            };

            settings.functions = {
              h = "left";
              j = "down";
              k = "up";
              l = "right";
              m = "pagedown";
              "," = "pageup";
            };
          };
        };
      };

    user = {
      extraGroups = [ "plugdev" ];
    };
  };
}
