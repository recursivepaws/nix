{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [ lohit-fonts.devanagari ];
  # Download and install Jaini font

  fonts.packages = [
    (pkgs.runCommand "jaini-font" {
      src = pkgs.fetchurl {
        url =
          "https://github.com/google/fonts/raw/main/ofl/jaini/Jaini-Regular.ttf";
        sha256 = "sha256-ZyJOYMr6JykcSwPNkHymHsZ4uln8F0OvidpEcupQ1cc=";
      };
    } ''
      mkdir -p $out/share/fonts/truetype
      cp $src $out/share/fonts/truetype/Jaini-Regular.ttf
    '')
  ];

  # Set Jaini as default for Devanagari
  fonts.fontconfig.localConf = ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
    <fontconfig>
      <match target="pattern">
        <test name="lang" compare="contains">
          <string>sa</string>
        </test>
        <edit name="family" mode="prepend">
          <string>Jaini</string>
        </edit>
      </match>
      <match target="pattern">
        <test name="lang" compare="contains">
          <string>hi</string>
        </test>
        <edit name="family" mode="prepend">
          <string>Jaini</string>
        </edit>
      </match>
    </fontconfig>
  '';
}
