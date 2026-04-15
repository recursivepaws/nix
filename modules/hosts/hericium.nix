{ den, ... }: {
  den.aspects.hericium = {
    includes = with den.aspects; [ amd gpu ];
    nixos = { pkgs, ... }: { environment.systemPackages = [ pkgs.hello ]; };
    provides.to-users.homeManager = { pkgs, ... }: {
      home.packages = [ pkgs.neovim ];
    };
  };
}
