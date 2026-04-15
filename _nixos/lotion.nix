{ pkgs ? import <nixpkgs> { } }:
let
  electronDeps = [
    pkgs.glib
    pkgs.gtk3
    pkgs.nss
    pkgs.nspr
    pkgs.dbus
    pkgs.atk
    pkgs.cups
    pkgs.pango
    pkgs.cairo
    pkgs.libx11
    pkgs.libxcomposite
    pkgs.libxdamage
    pkgs.libxext
    pkgs.libxfixes
    pkgs.libxrandr
    pkgs.libgbm
    pkgs.expat
    pkgs.libxcb
    pkgs.libxkbcommon
    pkgs.alsa-lib
  ];
in pkgs.stdenv.mkDerivation {
  pname = "lotion";
  version = "1.5.0";

  src = pkgs.fetchurl {
    url =
      "https://github.com/puneetsl/lotion/releases/download/v1.5.0/Lotion-linux-x64-1.5.0.zip";
    sha256 = "sha256-oSLWDExUKRmwR1uix1DnGPnQfKarn1VYm4t6L+m1LYQ=";
  };

  buildInputs = [ pkgs.unzip pkgs.makeWrapper ] ++ electronDeps;

  installPhase = ''
    mkdir -p $out/bin
    unzip $src -d $out

    wrapProgram $out/Lotion-linux-x64/lotion \
      --prefix LD_LIBRARY_PATH : "${pkgs.lib.makeLibraryPath electronDeps}" \

    ln -s $out/Lotion-linux-x64/lotion $out/bin/lotion

    mkdir -p $out/share/applications
    cat > $out/share/applications/lotion.desktop <<EOF
    [Desktop Entry]
    Name=Lotion
    Exec=$out/bin/lotion
    Icon=$out/Lotion-linux-x64/resources/app/icon.png
    Terminal=false
    Type=Application
    Categories=Productivity;
    EOF
  '';

  meta = with pkgs.lib; {
    description = "Unofficial Notion.so Electron desktop app";
    homepage = "https://github.com/puneetsl/lotion";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
