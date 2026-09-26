{ den, ... }:
{
  den.aspects.vera = {
    includes = [
      den.provides.define-user
      (den.provides.user-shell "zsh")
    ]
    ++ (with den.aspects; [
      bitwig-studio
      windows-vst
      native-vst-plugins
      davinci
      varnam
      gaming
      crypto
    ]);

    homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          handbrake
          avidemux
          telegram-desktop
          signal-desktop
          # discord
          vesktop
          discordchatexporter-desktop
          seahorse
          immich-go
          anki
          r2modman
          blender
          intiface-central
          deluge
          foliate
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
