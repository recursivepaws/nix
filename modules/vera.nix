{ den, ... }: {
  den.aspects.vera = {
    includes = [
      den.provides.define-user
      den.provides.primary-user
      (den.provides.user-shell "zsh")
    ];
    homeManager = { pkgs, ... }: { home.packages = [ pkgs.htop ]; };

    provides.to-hosts.nixos = { pkgs, ... }: { };
  };
}
