{
  den.aspects.music = {
    homeManager =
      { pkgs, config, ... }:
      {
        home.packages = with pkgs; [
          rmpc
          nicotine-plus
          pavucontrol
        ];
        services = {
          mpd = {
            enable = true;
            musicDirectory = "${config.home.homeDirectory}/Music/beets";
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
          mpdscribble = {
            enable = true;
            verbose = 3;
            endpoints = {
              "last.fm" = {
                passwordFile = "/run/agenix/lastfm";
                username = "recursivepaws";
              };
              # "listenbrainz" = {
              #   passwordFile = "/run/secrets/listenbrainz";
              #   username = "recursivepaws";
              # };
            };
          };
        };
      };
  };
}
