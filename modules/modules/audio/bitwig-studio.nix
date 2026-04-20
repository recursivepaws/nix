{
  den.aspects.bitwig-studio = {
    homeManager = { pkgs, ... }:
      let
        bitwig-theme-editor = let
          description = "Bitwig Theme Editor";
          pname = "bitwig-theme-editor";
          version = "2.3.1";
        in pkgs.stdenv.mkDerivation rec {
          inherit pname version;
          src = let filename = "${pname}-${version}-hotfix.jar";
          in pkgs.fetchurl {
            name = filename;
            url =
              "https://github.com/Berikai/${pname}/releases/download/${version}/${filename}";
            hash = "sha256-Fkz1s5DY8Ey3Il7CBHNmV87JyJ8clSEF1CltVwlq3/w=";
          };

          nativeBuildInputs = with pkgs; [ jre makeWrapper copyDesktopItems ];

          # Skip the normal build phases — there's nothing to compile
          dontUnpack = true;
          dontBuild = true;

          desktopItems = [
            (pkgs.makeDesktopItem {
              name = pname;
              exec = pname;
              icon = pname;
              desktopName = description;
              comment = description;
              categories = [ "Utility" ];
            })
          ];

          installPhase = ''
            # Install the JAR
            mkdir -p $out/share/java
            cp $src $out/share/java/${pname}.jar

            # Create a wrapper script in bin/
            mkdir -p $out/bin
            makeWrapper ${pkgs.jre}/bin/java $out/bin/${pname} \
              --add-flags "-jar $out/share/java/${pname}.jar"
          '';

          meta = {
            description = description;
            mainProgram = pname;
          };
        };

        bitwig-studio-deb = let version = "6.0";
        in pkgs.fetchurl {
          name = "bitwig-studio-${version}.deb";
          url =
            "https://www.bitwig.com/dl/Bitwig%20Studio/${version}/installer_linux";
          hash = "sha256-jrCTgaxfeWhfKwLeKLmqTQWS7RVbVnHqJ0InCipmm8k=";
        };

        bitwig6-local = pkgs.stdenv.mkDerivation {
          pname = "bitwig-studio-local";
          version = "6.0";
          src = bitwig-studio-deb;

          nativeBuildInputs = with pkgs; [
            dpkg
            makeWrapper
            jdk
            bitwig-theme-editor
          ];

          unpackPhase = "dpkg-deb -x $src .";

          installPhase = ''
            mkdir -p $out/bin $out/libexec $out/share

            # Copy the app files
            cp -r opt/bitwig-studio/* $out/libexec/

            # COPY THE ICONS AND DESKTOP FILES (This was missing!)
            cp -r usr/share/* $out/share/

            # Patch the bitwig jar to use the theme editor
            rm $out/libexec/bin/bitwig.jar

            cp ${./bitwig.jar} $out/libexec/bin/bitwig.jar

            #
            # echo "contents:"
            # echo $(ls /build/.bitwig-theme-editor)
            #
            # mkdir -p $out/share/bitwig/
            # cp -r /build/.bitwig-theme-editor $out/share/bitwig/

            # Link the binary
            ln -s $out/libexec/bitwig-studio $out/bin/bitwig-studio
          '';
        };

        # Bitwig FHS
        bitwig-fhs = pkgs.buildFHSEnv {
          name = "bitwig-studio";
          targetPkgs = p:
            with p; [
              bitwig6-local
              zlib
              libjack2
              libpulseaudio
              icu
              # Graphics & X11
              xorg.libX11
              xorg.libXcursor
              xorg.libXext
              xorg.libXfixes
              xorg.libXi
              xorg.libXrender
              xorg.libXtst
              libxcb
              xcbutilxrm
              xorg.xcbutilwm
              xorg.xcbutilimage
              libxcb-util
              xorg.xcbutilkeysyms
              xorg.xcbutilrenderutil
              libxcursor
              libx11
              libxtst
              libxkbcommon
              harfbuzz
              curl
              libudev-zero
              # System Deps
              alsa-lib
              at-spi2-atk
              cairo
              cups
              dbus
              expat
              fontconfig
              freetype
              mesa
              gdk-pixbuf
              glib
              gtk3
              libGL
              libglvnd
              libxkbcommon
              nspr
              nss
              pango
              pipewire
              stdenv.cc.cc.lib
              vulkan-loader
              zlib
              libGLU
              libGLX
              libGL
              freeglut
              libglvnd
              glibc
            ];
          runScript = "bitwig-studio";
          extraInstallCommands = ''
            mkdir -p $out/share/icons/hicolor/scalable/apps
            mkdir -p $out/share/applications

            # Link icons from our fixed local build
            # Note: Using a wildcard *bitwig* ensures we catch whatever name they used
            cp ${bitwig6-local}/share/icons/hicolor/scalable/apps/*.svg \
               $out/share/icons/hicolor/scalable/apps/bitwig-studio.svg

            # Link the desktop file
            cp ${bitwig6-local}/share/applications/*.desktop \
               $out/share/applications/bitwig-studio.desktop
          '';
        };
      in {
        home.packages = [
          bitwig-theme-editor
          bitwig-fhs
          pkgs.curl
          pkgs.libGL
          pkgs.libGLU
          pkgs.libGLX
        ];
        xdg.enable = true;
        xdg.desktopEntries.bitwig-studio = {
          name = "Bitwig Studio";
          exec = "bitwig-studio %U";
          terminal = false;
          icon = "bitwig-studio";
          categories = [ "AudioVideo" "Audio" "Midi" ];
          settings = { StartupWMClass = "com.bitwig.BitwigStudio"; };
        };
      };
  };
}
