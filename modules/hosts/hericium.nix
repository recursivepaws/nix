{ den, ... }: {
  den.aspects.hericium = {
    includes = [ den.aspects.amd ];
    nixos = { pkgs, ... }: { environment.systemPackages = [ pkgs.hello ]; };
    provides.to-users.homeManager = { pkgs, ... }: {
      home.packages = [ pkgs.neovim ];
    };
  };
}
