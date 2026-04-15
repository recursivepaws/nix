{
  den.aspects.hericium = {
    nixos = { pkgs, ... }: { environment.systemPackages = [ pkgs.hello ]; };
    provides.to-users.homeManager = { pkgs, ... }: {
      home.packages = [ pkgs.neovim ];
    };
  };
}
