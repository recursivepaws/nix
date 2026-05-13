{ den, ... }:
{
  den.aspects.work = {
    includes = [
      den.provides.define-user
      (den.provides.user-shell "zsh")
    ]
    ++ (with den.aspects; [ hightouch ]);
    homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          seahorse
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
        "docker"
      ];
    };
  };
}
