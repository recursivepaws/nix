{ den, ... }:
{
  den.aspects.work = {
    includes = [
      den.provides.define-user
      den.provides.primary-user
      (den.provides.user-shell "zsh")
    ];
    homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          seahorse
          zoom-us
          slack
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
