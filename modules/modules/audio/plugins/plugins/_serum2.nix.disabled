{ stdenvNoCC, lib, pkgs, requireFile, }:

let
  _version = "2.0.22";
  serum2-installer = requireFile {
    name = "Install_Xfer_Serum2_${_version}.exe";
    sha256 = "09f7lplg4md58sq5b6a3lwp6nvaw4333lnhr314rwlk4ar1xrbr6";
    url =
      "https://xferrecords.com/product_downloads/serum-2-0-22-for-windows/start";
  };

in stdenvNoCC.mkDerivation {
  pname = "serum2";
  version = _version;
  src = serum2-installer;
  dontUnpack = true;

  nativeBuildInputs = with pkgs; [ wine-staging xvfb-run ];

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
