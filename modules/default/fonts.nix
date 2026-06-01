{
  den.default.nixos =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [ lohit-fonts.devanagari ];
      # Download and install Jaini font

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
              (pkgs.runCommand "jaini-font"
                {
                  src = pkgs.fetchurl {
                    url = "https://github.com/google/fonts/raw/main/ofl/jaini/Jaini-Regular.ttf";
                    sha256 = "sha256-ZyJOYMr6JykcSwPNkHymHsZ4uln8F0OvidpEcupQ1cc=";
                  };
                }
                ''
                  mkdir -p $out/share/fonts/truetype
                  cp $src $out/share/fonts/truetype/Jaini-Regular.ttf
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

        };
      };
    };
}
