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
      monarch
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
      # Traverse-only, so work's ~/Music symlink (hericium.nix) can reach /home/vera/Music.
      homeMode = "711";
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
