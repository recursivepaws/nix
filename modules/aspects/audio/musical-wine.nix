{ den, ... }:
{
  # den.aspects.musical-wine = {
  #   includes = [ den.aspects.custom-wine ];
  #   homeManager = { pkgs, lib, ... }:
  #     let
  #
  #       crystal = let
  #       in pkgs.stdenv.mkDerivation {
  #         src = pkgs.requireFile rec {
  #           name = "Crystal.zip";
  #           # sha256 = "09f7lplg4md58sq5b6a3lwp6nvaw4333lnhr314rwlk4ar1xrbr6";
  #           url = "https://www.greenoak.com/crystal/dl/${name}";
  #         };
  #         unpackPhase = "unzip $src .";
  #         installPhase = "\n";
  #       };
  #       /* serum2 = let
  #            pname = "serum2";
  #            version = "2.0.22";
  #            installer = pkgs.requireFile {
  #              name = "Install_Xfer_Serum2_${version}.exe";
  #              sha256 = "09f7lplg4md58sq5b6a3lwp6nvaw4333lnhr314rwlk4ar1xrbr6";
  #              url =
  #                "https://xferrecords.com/product_downloads/serum-2-0-22-for-windows/start";
  #            };
  #
  #          in pkgs.stdenvNoCC.mkDerivation {
  #            inherit pname version;
  #            src = installer;
  #            dontUnpack = true;
  #
  #            nativeBuildInputs = [ wineGiang pkgs.xvfb-run ];
  #
  #            installPhase = ''
  #              runHook preInstall
  #
  #              export HOME="$PWD"
  #              export WINEPREFIX="$PWD/serum"
  #              export XDG_CONFIG_HOME="$PWD/.config"
  #              export WINEDEBUG=-all
  #
  #              xvfb-run wineboot --init
  #              wineserver --wait
  #
  #              xvfb-run wine $src /S
  #              wineserver --wait
  #
  #              mkdir -p $out/lib/vst
  #
  #              cp -r "$WINEPREFIX/drive_c/Program Files/Common Files/VST3/Serum2.vst3" "$out"
  #              cp -r "$WINEPREFIX/drive_c/users/vera/Documents/Xfer/Serum 2 Presets" "$out"
  #
  #              runHook postInstall
  #            '';
  #
  #            meta = with lib; {
  #              description =
  #                "Advanced Wavetable Synthesizer by Xfer Records (via Yabridge)";
  #              homepage = "https://xferrecords.com/products/serum";
  #              license = licenses.unfree;
  #              platforms = [ "x86_64-linux" ];
  #            };
  #          };
  #       */
  #
  #
  #       # wine-router = pkgs.writeShellScriptBin "wine" ''
  #       #   # If the prefix contains serum, use the Giang17 audio build
  #       #   # If the prefix contains vst-wine-prefixes/default, use wine 9.21 for yabridge
  #       #   if [[ "$WINEPREFIX" == *"/serum"* ]]; then
  #       #     export WINEDLLOVERRIDES="d3d11,dxgi,d3d10core,d3d9=b"
  #       #     exec ${pkgs.wine-experimental}/bin/wine "$@"
  #       #   elif [[ "$WINEPREFIX" == *"vst-wine-prefixes/default"* ]]; then
  #       #       exec ${pkgs.wine-fallback}/bin/wine "$@"
  #       #   else
  #       #     # Fall back to the system-wide modern Wine for everything else
  #       #     exec ${pkgs.wine-stable}/bin/wine "$@"
  #       #   fi
  #       # '';
  #       #
  #       # wineserver-router = pkgs.writeShellScriptBin "wineserver" ''
  #       #   if [[ "$WINEPREFIX" == *"/serum"* ]]; then
  #       #       exec ${pkgs.wine-experimental}/bin/wineserver "$@"
  #       #   elif [[ "$WINEPREFIX" == *"vst-wine-prefixes/default"* ]]; then
  #       #       exec ${pkgs.wine-fallback}/bin/wineserver "$@"
  #       #   else
  #       #       # Fall back to the system-wide modern Wine for everything else
  #       #       exec ${pkgs.wine-stable}/bin/wineserver "$@"
  #       #   fi
  #       # '';
  #       #
  #       # winetricks-router = pkgs.writeShellScriptBin "winetricks" ''
  #       #   if [[ "$WINEPREFIX" == *"/serum"* ]]; then
  #       #     export WINE="${pkgs.wine-experimental}/bin/wine"
  #       #     export WINESERVER="${pkgs.wine-experimental}/bin/wineserver"
  #       #   elif [[ "$WINEPREFIX" == *"vst-wine-prefixes/default"* ]]; then
  #       #     export WINE="${pkgs.wine-fallback}/bin/wine"
  #       #     export WINESERVER="${pkgs.wine-fallback}/bin/wineserver"
  #       #   else
  #       #     export WINE="${pkgs.wine-stable}/bin/wine"
  #       #     export WINESERVER="${pkgs.wine-stable}/bin/wineserver"
  #       #   fi
  #       #
  #       #   # Run the real winetricks with the real binary paths injected
  #       #   exec ${pkgs.winetricks}/bin/winetricks "$@"
  #       # '';
  #     in {
  #       home.packages = [
  #         # wine-router
  #         # wineserver-router
  #         # winetricks-router
  #         # serum2
  #         pkgs.curl
  #         pkgs.libGL
  #         pkgs.libGLU
  #         pkgs.libGLX
  #         pkgs.yabridgectl
  #       ];
  #
  #       # If the bitwig icon doesn't work for you:
  #
  #       # home.file.".vst3/Serum2.vst3".source = "${serum2}/Serum2.vst3";
  #
  #       # # Configure the theme editor
  #       # home.activation.setupBitwigTheme =
  #       #   lib.hm.dag.entryAfter [ "writeBoundary" ] ''
  #       #     echo "Setting up Bitwig theme editor..."
  #       #     ln ${bitwig6-local}/share/bitwig/.bitwig-theme-editor ${bitwig6-local}/libexec/bin/bitwig.jar
  #       #   '';
  #
  #       home.sessionVariables = {
  #         # You need this for Kilohearts plugins
  #         WINEFSYNC = "1";
  #       };
  #     };
  #
  # };
}
