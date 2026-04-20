{ inputs, ... }: {
  # BUG: https://github.com/NixOS/nixpkgs/issues/448456
  # terrible terrible terrible terrible terrible
  flake-file.inputs.mesa-good.url =
    "github:nixos/nixpkgs?ref=599ddd2b79331c1e6153e1659bdaab65d62c4c82";

  den.aspects.davinci = {
    nixos = { pkgs, lib, ... }:
      let
        studio-variant = true;
        mesa-good-pkg = inputs.mesa-good.legacyPackages.x86_64-linux.mesa;
        original = if studio-variant then
          pkgs.davinci-resolve-studio
        else
          pkgs.davinci-resolve;
        davinci = original.passthru.davinci;
        davinci-fixed = pkgs.buildFHSEnv {
          pname = davinci.pname;
          version = davinci.version;

          # original.extraPreBwrapCmds is exposed, but it does not respect our studio-variant flag, so we inline it here:
          extraPreBwrapCmds = lib.optionalString studio-variant ''
            mkdir -p ~/.local/share/DaVinciResolve/license || exit 1
            mkdir -p ~/.local/share/DaVinciResolve/Extras || exit 1
          '';

          # original.extraBwrapArgs is exposed, but it does not respect our studio-variant flag, so we inline it here:
          extraBwrapArgs = lib.optionals studio-variant [
            ''
              --bind "$HOME"/.local/share/DaVinciResolve/license ${davinci}/.license''
            ''
              --bind "$HOME"/.local/share/DaVinciResolve/Extras ${davinci}/Extras''
          ] ++ [ "--chdir" "$HOME" ];

          runScript = "${pkgs.bash}/bin/bash ${
              pkgs.writeText "davinci-wrapper-goodmesa" ''
                export QT_XKB_CONFIG_ROOT="${pkgs.xkeyboard_config}/share/X11/xkb"
                export QT_PLUGIN_PATH="${davinci}/libs/plugins:$QT_PLUGIN_PATH"

                export LD_LIBRARY_PATH=${mesa-good-pkg}/lib:${mesa-good-pkg}/lib/dri:$LD_LIBRARY_PATH
                export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/lib:/usr/lib32:${davinci}/libs

                exec ${davinci}/bin/resolve
              ''
            }";

          # we inline extraInstallCommands instead of referencing orig.extraInstallCommands, as it is not exposed
          extraInstallCommands = ''
            mkdir -p $out/share/applications $out/share/icons/hicolor/128x128/apps
            ln -s ${davinci}/share/applications/*.desktop $out/share/applications/
            ln -s ${davinci}/graphics/DV_Resolve.png $out/share/icons/hicolor/128x128/apps/davinci-resolve${
              lib.optionalString studio-variant "-studio"
            }.png
          '';

          # we inline targetPkgs instead of referencing orig.targetPkgs, as it is not exposed
          targetPkgs = pkgs:
            with pkgs; [
              # our addition:
              mesa-good-pkg

              # original dependencies:
              alsa-lib
              aprutil
              bzip2
              davinci
              dbus
              expat
              fontconfig
              freetype
              glib
              libGL
              libGLU
              libarchive
              libcap
              librsvg
              libtool
              libuuid
              libxcrypt
              libxkbcommon
              nspr
              ocl-icd
              opencl-headers
              python3
              python3.pkgs.numpy
              udev
              xdg-utils
              xorg.libICE
              xorg.libSM
              xorg.libX11
              xorg.libXcomposite
              xorg.libXcursor
              xorg.libXdamage
              xorg.libXext
              xorg.libXfixes
              xorg.libXi
              xorg.libXinerama
              xorg.libXrandr
              xorg.libXrender
              xorg.libXt
              xorg.libXtst
              xorg.libXxf86vm
              xorg.libxcb
              xorg.xcbutil
              xorg.xcbutilimage
              xorg.xcbutilkeysyms
              xorg.xcbutilrenderutil
              xorg.xcbutilwm
              xorg.xkeyboardconfig
              zlib
            ];

          passthru = original.passthru;
          meta = original.meta;
        };
      in { environment.systemPackages = [ davinci-fixed ]; };
  };
}
