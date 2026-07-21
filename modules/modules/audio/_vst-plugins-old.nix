{ ... }:
let
  native = [
    "https://github.com/ZL-Audio/ZLEqualizer/releases/download/1.1.0/ZL.Equalizer.2-1.1.0-Linux-x86.zip"
    "https://plugins4free.com/get_plug/tunefish-v3.3-linux64-vst24.tar.gz"
    "https://plugins4free.com/get_plug/Wavetable_Linux.zip"
    "https://plugins4free.com/get_plug/RaveGenerator2-Linux.tar.gz"
    "https://plugins4free.com/get_plug/TripleCheese_130_12092_Linux.tar.xz"
    "https://plugins4free.com/get_plug/TAL-NoiseMaker_64_linux.zip"
    "https://dl.u-he.com/releases/TyrellN6_300_public_beta_16976_Linux.tar.xz"
    "https://github.com/utokusa/OS-251/releases/download/v1.3.0/OS-251-Linux.zip"
    "https://github.com/sadko4u/lsp-plugins/releases/download/1.2.29/lsp-plugins-1.2.29-Linux-x86_64.7z"
    "https://github.com/xunil-cloud/CloudReverb/releases/download/v0.5/CloudReverb-v0.5-Linux-x86_64.zip"
    # "https://github.com/Dimethoxy/Plasma/releases/download/v1.2.1/plasma-v1.2.1-linux.tar.gz"
    "https://plugins4free.com/get_plug/js80p-linux.zip"
    "https://plugins4free.com/get_plug/helm_Linux.zip"
    "https://plugins4free.com/get_plug/Zebra2_293_12092_Linux.tar.xz"
    "https://plugins4free.com/get_plug/gRainbow-Linux.zip"
  ];

  fetchAndInstall =
    url:
    let
      filename = baseNameOf url;
      extractCmd =
        if builtins.match ".*\\.zip" filename != null then
          "unzip -q $tmp/${filename} -d $tmp"
        else if builtins.match ".*\\.tar\\.gz" filename != null then
          "tar xzf $tmp/${filename} -C $tmp"
        else if builtins.match ".*\\.tar\\.xz" filename != null then
          "tar xJf $tmp/${filename} -C $tmp"
        else if builtins.match ".*\\.7z" filename != null then
          "7z x $tmp/${filename} -o$tmp"
        else
          "tar xf $tmp/${filename} -C $tmp";
    in
    ''
      echo "Fetching ${filename}..."
      tmp=$(mktemp -d)
      curl -fsSL --retry 3 -o "$tmp/${filename}" "${url}"
      ${extractCmd}

      vst3_found=0
      find "$tmp" -maxdepth 6 -type d \( -name "*.vst3" -o -name "*-vst3" \) | while read -r vst3dir; do
        dest="$HOME/.vst3/$(basename "$vst3dir")"
        echo "Installing VST3 $(basename "$vst3dir") -> $HOME/.vst3/"
        rm -rf "$dest"
        cp -r "$vst3dir" "$dest"
        vst3_found=1
      done

      if [ "$vst3_found" -eq 0 ]; then
        echo "Failed to install ${filename}"
        # find "$tmp" -maxdepth 6 -type f -name "*64*.so" | while read -r so; do
        #   mkdir -p "$HOME/.vst"
        #   dest="$HOME/.vst/$(basename "$so")"
        #   echo "Installing VST2 $(basename "$so") -> $HOME/.vst/"
        #   cp "$so" "$dest"
        # done
      fi

      rm -rf "$tmp"
    '';
  installScript = builtins.concatStringsSep "\n" (map fetchAndInstall native);
in
{
  # den.aspects.vst-plugins = {
  #   homeManager = { pkgs, lib, ... }: {
  #     home.activation.installVstPlugins =
  #       let libs = with pkgs; [ curl unzip gnutar gzip xz findutils p7zip ];
  #       in lib.hm.dag.entryAfter [ "writeBoundary" ] ''
  #         export PATH="${lib.makeBinPath libs}:$PATH"
  #         mkdir -p "$HOME/.vst3"
  #         ${installScript}
  #       '';
  #   };
  # };
}
