{ stdenvNoCC, lib, pkgs, requireFile, }:

let
  _version = "2.0.23";

  serum2-installer = requireFile {
    name = "Install_Xfer_Serum2_${_version}.exe";
    sha256 = "09spxdlpy67wdq5mx95gjcda5zy70fxjdaj8zsacp9nsl1phkh8r";
    url = "https://xferrecords.com/product_downloads/serum-2";
  };

in stdenvNoCC.mkDerivation {
  pname = "serum2";
  version = _version;
  src = serum2-installer;
  dontUnpack = true;

  nativeBuildInputs = [ pkgs.wine-staging pkgs.xvfb-run ];

  installPhase = ''
    runHook preInstall

    # export WINEARCH="win64"
    export WINEPREFIX="$PWD/wineprefix"
    export XDG_CONFIG_HOME="$PWD/.config"

    xvfb-run wine $src /S

    mkdir -p $out/lib/vst

    cp -r "$WINEPREFIX/drive_c/Program Files/Common Files/VST3/Serum2.vst3" "$out"
    cp -r "$WINEPREFIX/drive_c/users/nixbld/Documents/Xfer/Serum 2 Presets" "$out"

    runHook postInstall
  '';

  meta = with lib; {
    description =
      "Advanced Wavetable Synthesizer by Xfer Records (via Yabridge)";
    homepage = "https://xferrecords.com/products/serum";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
  };
}
