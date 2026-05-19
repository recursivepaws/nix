{ ... }:

let
  mkVarnamPackages = pkgs: rec {
    # govarnam prebuilt release zip contains: libgovarnam.so, all C headers
    # (including the CGO-generated libgovarnam.h), govarnam.pc, and varnamcli.
    # We rewrite the .pc file so it points at the Nix store path.
    govarnam-lib = pkgs.stdenv.mkDerivation {
      pname = "govarnam";
      version = "1.9.1";
      src = pkgs.fetchzip {
        url = "https://github.com/varnamproject/govarnam/releases/download/v1.9.1/govarnam-1.9.1-x86_64.zip";
        hash = "sha256-CYPylkgcwD0QtVpraWYDhRf0Z7Ma/Q1SGQkXI85XFvU=";
      };
      nativeBuildInputs = [ pkgs.autoPatchelfHook ];
      installPhase = ''
        mkdir -p $out/lib/pkgconfig $out/include/libgovarnam $out/bin

        install -m755 libgovarnam.so $out/lib/libgovarnam.so.1.9.1
        ln -sf libgovarnam.so.1.9.1 $out/lib/libgovarnam.so.1
        ln -sf libgovarnam.so.1     $out/lib/libgovarnam.so

        # All headers: hand-written C API (c-shared*.h) + CGO-generated (libgovarnam.h)
        install -m644 *.h $out/include/libgovarnam/

        install -m755 varnamcli $out/bin/

        # Write pkg-config pointing at this store path
        cat > $out/lib/pkgconfig/govarnam.pc << EOF
        prefix=$out
        libdir=''${prefix}/lib
        includedir=''${prefix}/include

        Name: GoVarnam
        Description: A transliteration library for Indian languages
        Version: 1.9.1
        URL: http://varnamproject.com
        Libs: -L''${libdir} -lgovarnam
        Cflags: -I''${includedir}
        EOF
      '';
    };

    # Fcitx5 input engine for Varnam, built from source.
    # Uses CMake + extra-cmake-modules; links against govarnam-lib and fcitx5.
    # On first build this hash will be wrong — update it from the error output.
    varnam-fcitx5 = pkgs.stdenv.mkDerivation {
      pname = "varnam-fcitx5";
      version = "0.0.2";
      src = pkgs.fetchFromGitHub {
        owner = "varnamproject";
        repo = "varnam-fcitx5";
        rev = "v0.0.2";
        hash = "sha256-LLZXuzi3fpx92OO9DbTADLxVZVoEBMEE6CtvV7+in0s=";
      };
      nativeBuildInputs = with pkgs; [
        cmake
        extra-cmake-modules
        pkg-config
      ];
      buildInputs = [
        govarnam-lib
        pkgs.fcitx5
      ];
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
          type = "fcitx5";
          fcitx5.addons = [
            p.varnam-fcitx5
            pkgs.fcitx5-gtk # GTK3 IM module; GTK4/Qt6/Chrome use Wayland protocol natively
          ];
          # waylandFrontend = true: fcitx5 implements zwp_input_method_v2, so
          # candidates follow the cursor in all Wayland-native apps (GTK4, Qt6,
          # Chrome) without any extra env vars.
          fcitx5.waylandFrontend = true;
        };

        # govarnam searches for *.vst scheme files in (priority order):
        #   $VARNAM_VST_DIR -> ./schemes -> /usr/local/share/varnam/schemes -> /usr/share/varnam/schemes
        environment.sessionVariables.VARNAM_VST_DIR = "${p.sa-scheme}";

        environment.systemPackages = [
          p.govarnam-lib # varnamcli in PATH for the one-time vocabulary import
          pkgs.kdePackages.fcitx5-configtool
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
