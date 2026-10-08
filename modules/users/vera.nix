{ den, ... }:
{
  den.aspects.vera = {
    includes = [
      den.provides.define-user
      (den.provides.user-shell "zsh")
    ]
    ++ (with den.aspects; [
      bitwig-studio
      dj
      rekordbox
      windows-vst
      native-vst-plugins
      davinci
      varnam
      gaming
      crypto
      syncthing
      messaging
    ]);

    homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          handbrake
          avidemux
          seahorse
          immich-go
          anki
          r2modman
          blender
          intiface-central
          deluge
        ];
      };

    user = {
      extraGroups = [
        "video"
        "audio"
        "wheel"
        "render"
        "networkmanager"
        "secrets"
      ];
    };
  };
}
