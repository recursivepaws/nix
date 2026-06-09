{
  den.aspects.music = {
    homeManager =
      { pkgs, config, ... }:
      {
        home.packages = with pkgs; [ rmpc ];
        services = {
          mpd = {
            enable = true;
            musicDirectory = "${config.home.homeDirectory}/Music";
            extraConfig = ''
              audio_output {
                type    "pipewire"
                name    "pipewire"
              }
              auto_update "no"
              replaygain "auto"
              zeroconf_enabled "no"
            '';
          };

          mpd-mpris.enable = true;
        };
      };
  };
}
