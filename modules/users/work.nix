{ den, ... }:
{
  den.aspects.work = {
    includes = [
      den.provides.define-user
      den.provides.primary-user
      (den.provides.user-shell "zsh")
    ];
    homeManager =
      { pkgs, config, ... }:
      {
        home.packages = with pkgs; [
          eog
          cameractrls
          playerctl
          wl-clipboard
          chezmoi
          baobab
          seahorse
          zoom-us
        ];

        home.file."${config.xdg.configHome}/starship.toml".source = pkgs.fetchurl {
          url = "https://raw.githubusercontent.com/EdenEast/nightfox.nvim/refs/heads/main/extra/carbonfox/starship.toml";
          hash = "sha256-NneOWmWRhL5sgP/qFSSeVhf41W+waiadwz+KXL7s04s=";
        };

        systemd.user.startServices = "sd-switch";
        programs = {
          home-manager.enable = true;
        };
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
