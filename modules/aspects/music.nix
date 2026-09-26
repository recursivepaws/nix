{
  den.aspects.music = {
    homeManager =
      { pkgs, config, ... }:
      let
        dj-scrobbler =
          let
            version = "0.6.1";
            src = pkgs.fetchurl {
              url = "https://github.com/ericcastro/dj-scrobbler/releases/download/v${version}/DJ-Scrobbler-${version}.AppImage";
              hash = "sha256-j03yPcUcmaPPvIIY4maXSMfUVbL0qX+eWOJHpPUxXps=";
            };
            contents = pkgs.appimageTools.extractType2 {
              inherit version src;
              pname = "dj-scrobbler";
            };
          in
          pkgs.appimageTools.wrapType2 {
            inherit version src;
            pname = "dj-scrobbler";
            # /etc is a tmpfs inside the FHS sandbox, so launching from a cwd
            # under /etc (e.g. /etc/nixos) fails bwrap's --chdir.
            chdirToPwd = false;
            extraInstallCommands = ''
              install -Dm444 ${contents}/dj-scrobbler.desktop -t $out/share/applications
              substituteInPlace $out/share/applications/dj-scrobbler.desktop \
                --replace-fail 'Exec=AppRun' 'Exec=dj-scrobbler'
              cp -r ${contents}/usr/share/icons $out/share
            '';
          };
      in
      {
        home.packages = with pkgs; [
          rmpc
          nicotine-plus
          pavucontrol
          dj-scrobbler
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
