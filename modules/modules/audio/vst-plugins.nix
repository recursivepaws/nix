{ ... }:
let
  native = [
    "https://github.com/ZL-Audio/ZLEqualizer/releases/download/1.1.0/ZL.Equalizer.2-1.1.0-Linux-x86.zip"
    "https://plugins4free.com/get_plug/tunefish-v3.3-linux64-vst24.tar.gz"
    "https://plugins4free.com/get_plug/Wavetable_Linux.zip"
    "https://plugins4free.com/get_plug/RaveGenerator2-Linux.tar.gz"
    "https://plugins4free.com/get_plug/TripleCheese_130_12092_Linux.tar.xz"
    "https://plugins4free.com/get_plug/TAL-NoiseMaker_64_linux.zip"
    "https://plugins4free.com/get_plug/TyrellN6_V303_Linux.tar.gz"
    "https://plugins4free.com/get_plug/js80p-linux.zip"
    "https://plugins4free.com/get_plug/helm_Linux.zip"
    "https://plugins4free.com/get_plug/Zebra2_293_12092_Linux.tar.xz"
    "https://plugins4free.com/get_plug/gRainbow-Linux.zip"
  ];

  fetchAndInstall = url:
    let
      filename = baseNameOf url;
      extractCmd = if builtins.match ".*\\.zip" filename != null then
        "unzip -q $tmp/${filename} -d $tmp"
      else if builtins.match ".*\\.tar\\.gz" filename != null then
        "tar xzf $tmp/${filename} -C $tmp"
      else if builtins.match ".*\\.tar\\.xz" filename != null then
        "tar xJf $tmp/${filename} -C $tmp"
      else
        "tar xf $tmp/${filename} -C $tmp";
    in ''
      echo "Fetching ${filename}..."
      tmp=$(mktemp -d)
      curl -fsSL --retry 3 -o "$tmp/${filename}" "${url}"
      ${extractCmd}
      echo $(ls "$tmp")
      find "$tmp" -maxdepth 4 -type d -name "*.vst3" | while read -r vst3dir; do
        dest="$HOME/.vst3/$(basename "$vst3dir")"
        echo "Installing $(basename "$vst3dir") -> $HOME/.vst3/"
        rm -rf "$dest"
        cp -r "$vst3dir" "$dest"
      done
      rm -rf "$tmp"
    '';
  installScript = builtins.concatStringsSep "\n" (map fetchAndInstall native);
in {
  den.aspects.vst-plugins = {
    homeManager = { pkgs, lib, ... }: {
      home.activation.installVstPlugins =
        let libs = with pkgs; [ curl unzip gnutar gzip xz findutils ];
        in lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          export PATH="${lib.makeBinPath libs}:$PATH"
          mkdir -p "$HOME/.vst3"
          ${installScript}
        '';
    };
  };
}
