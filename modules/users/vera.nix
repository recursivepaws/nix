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
          eog
          handbrake
          avidemux
          cameractrls
          playerctl
          wl-clipboard
          fuzzel
          spotifyd
          chezmoi
          telegram-desktop
          signal-desktop
          discord
          gnome-disk-utility
          baobab
          seahorse
          immich-go
          zoom-us
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
