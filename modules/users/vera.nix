{ den, ... }:
{
  den.aspects.vera = {
    includes = [
      den.provides.define-user
      den.provides.primary-user
      (den.provides.user-shell "zsh")
    ];
    homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          handbrake
          avidemux
          fuzzel
          spotifyd
          chezmoi
          telegram-desktop
          signal-desktop
          discord
          seahorse
          immich-go
        ];
      };

    provides.to-hosts.nixos =
      { pkgs, ... }:
      {
        users.groups.secrets = { };
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
