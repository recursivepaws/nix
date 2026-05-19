{ den, ... }:

let
  mkVarnamPackages =
    pkgs:
    rec {
      # govarnam shared library — the IBus engine binary dynamically links
      # against libgovarnam.so.1 at runtime.
      govarnam-lib = pkgs.stdenv.mkDerivation {
        pname = "govarnam";
        version = "1.9.1";
        src = pkgs.fetchzip {
          url = "https://github.com/varnamproject/govarnam/releases/download/v1.9.1/govarnam-1.9.1-x86_64.zip";
          hash = "sha256-CYPylkgcwD0QtVpraWYDhRf0Z7Ma/Q1SGQkXI85XFvU=";
        };
        nativeBuildInputs = [ pkgs.autoPatchelfHook ];
        installPhase = ''
          mkdir -p $out/lib $out/bin
          install -m755 libgovarnam.so $out/lib/
          ln -s libgovarnam.so $out/lib/libgovarnam.so.1
          install -m755 varnamcli $out/bin/
        '';
      };

      # Pre-built IBus engine binary, ELF-patched for NixOS by autoPatchelfHook.
      #
      # The component XML is written into share/ibus/component/ so that NixOS's
      # ibus module picks it up when building ibus-with-plugins.  The NixOS wrapper
      # hard-codes IBUS_COMPONENT_PATH to the ibus-with-plugins store path, so
      # ~/.local/share/ibus/component/ is never scanned — the XML must live inside
      # the package that is passed to i18n.inputMethod.ibus.engines.
      #
      # $out is available during installPhase (Nix sets it before the build),
      # so embedding it in the XML is safe and produces correct store paths.
      varnam-ibus-engine = pkgs.stdenv.mkDerivation {
        pname = "varnam-ibus-engine";
        version = "1.6.4";
        src = pkgs.fetchzip {
          url = "https://github.com/varnamproject/govarnam-ibus/releases/download/v1.6.4/varnam-ibus-engine-1.6.4-x86_64.zip";
          hash = "sha256-VzmOzTinzhzu95ZtZ9uIzFzImE74N3+zgkRO1Kgkg40=";
        };
        nativeBuildInputs = [ pkgs.autoPatchelfHook ];
        buildInputs = with pkgs; [
          govarnam-lib
          gtk3
        ];
        meta.isIbusEngine = true;

        installPhase = ''
          mkdir -p $out/bin $out/share/varnam/ibus/icons $out/share/ibus/component
          install -m755 varnam-ibus-engine $out/bin/
          cp icons/*.png $out/share/varnam/ibus/icons/

          cat > $out/share/ibus/component/varnam-sa.xml << EOF
          <?xml version="1.0" encoding="UTF-8"?>
          <component>
              <name>org.freedesktop.IBus.GoVarnam.sa</name>
              <description>Varnam-sa Input Engine</description>
              <version>1.6.4</version>
              <license>AGPL-3.0</license>
              <author>Subin Siby</author>
              <homepage>https://varnamproject.github.io</homepage>
              <exec>$out/bin/varnam-ibus-engine -ibus -s sa -lang sa</exec>
              <textdomain>ibus-varnam-sa</textdomain>
              <engines>
                  <engine>
                      <name>varnam-sa</name>
                      <longname>Varnam-sa</longname>
                      <description>Varnam-sa Input Method</description>
                      <language>sa</language>
                      <license>AGPL-3.0</license>
                      <author>Subin Siby</author>
                      <layout>en</layout>
                      <rank>0</rank>
                      <setup>$out/bin/varnam-ibus-engine -prefs -s sa -lang sa</setup>
                      <version>1.6.4</version>
                  </engine>
              </engines>
          </component>
          EOF
        '';
      };

      # Sanskrit VST scheme file.
      # fetchzip strips the single top-level directory so ${sa-scheme}/sa.vst
      # is the path govarnam needs.
      sa-scheme = pkgs.fetchzip {
        url = "https://github.com/varnamproject/schemes/releases/download/v1.8.0/sa.zip";
        hash = "sha256-p8P360lvuQG80nfPCiI8cX8SMGbit6UtLWu+XNoQNNM=";
      };
    };
in
{
  den.aspects.varnam = {
    nixos =
      { pkgs, ... }:
      let
        p = mkVarnamPackages pkgs;
      in
      {
        i18n.inputMethod = {
          enable = true;
          type = "ibus";
          # Adding the engine package here causes the NixOS module to include
          # its share/ibus/component/ directory in IBUS_COMPONENT_PATH.
          ibus.engines = [ p.varnam-ibus-engine ];
          # waylandFrontend = true does NOT set GTK_IM_MODULE/QT_IM_MODULE.
          # Instead, GTK apps use GTK_IM_MODULE=wayland → zwp_text_input_v3
          # → ibus-portal bridges to IBus → candidates appear anchored to the
          # cursor, never in a separate floating window.
          ibus.waylandFrontend = true;
        };

        # govarnam searches for *.vst scheme files in (priority order):
        #   $VARNAM_VST_DIR -> ./schemes -> /usr/local/share/varnam/schemes -> /usr/share/varnam/schemes
        environment.sessionVariables.VARNAM_VST_DIR = "${p.sa-scheme}";

        environment.systemPackages = with p; [
          varnam-ibus-engine
          govarnam-lib # varnamcli in PATH for the one-time vocabulary import
        ];
      };

    homeManager =
      { ... }:
      {
        # NOTE: first-time vocabulary import
        # Varnam transliterates without imported words, but word suggestions
        # need a learnings file.  Run once after rebuilding:
        #
        #   cd $VARNAM_VST_DIR && ./import.sh
        #
        # Writes to ~/.local/share/varnam/learnings/sa.vst.learnings
      };
  };
}
