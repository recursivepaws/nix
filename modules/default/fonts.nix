{
  den.default.nixos =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [ lohit-fonts.devanagari ];
      # Download and install Tiro Devanagari Sanskrit font

      fonts = {
        enableDefaultPackages = true;
        packages =
          let
            nerdFonts = with pkgs.nerd-fonts; [
              fira-code
              fira-mono
              caskaydia-cove
              caskaydia-mono
            ];
            standardFonts = with pkgs; [
              (pkgs.runCommand "tiro-devanagari-sanskrit-font"
                {
                  src = pkgs.fetchurl {
                    url = "https://github.com/google/fonts/raw/main/ofl/tirodevanagarisanskrit/TiroDevanagariSanskrit-Regular.ttf";
                    sha256 = "sha256-da6HPl4/nDD7lio9KDufXnvFvKV4IqKqkmdTspexUMo=";
                  };
                }
                ''
                  mkdir -p $out/share/fonts/truetype
                  cp $src $out/share/fonts/truetype/TiroDevanagariSanskrit-Regular.ttf
                ''
              )
              junicode
              noto-fonts
              noto-fonts-color-emoji
              liberation_ttf
              atkinson-hyperlegible
            ];
          in
          standardFonts ++ nerdFonts;

        fontconfig = {
          defaultFonts = {
            serif = [ "CaskaydiaCove Nerd Font" ];
            sansSerif = [ "CaskaydiaCove Nerd Font" ];
            monospace = [ "CaskaydiaCove Nerd Font Mono" ];
            emoji = [ "Noto Color Emoji" ];
          };
          localConf = ''
            <?xml version="1.0"?>
            <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
            <fontconfig>
              <match target="pattern">
                <test name="lang" compare="contains">
                  <string>sa</string>
                </test>
                <edit name="family" mode="prepend">
                  <string>Tiro Devanagari Sanskrit</string>
                </edit>
              </match>
              <match target="pattern">
                <test name="lang" compare="contains">
                  <string>hi</string>
                </test>
                <edit name="family" mode="prepend">
                  <string>Tiro Devanagari Sanskrit</string>
                </edit>
              </match>
            </fontconfig>
          '';

        };
      };
    };
}
