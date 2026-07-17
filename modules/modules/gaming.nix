{
  den.aspects.gaming = {
    nixos = { pkgs, ... }: {

      environment.systemPackages = [
        (pkgs.heroic.override {
          extraPkgs = pkgs: [
            pkgs.gamescope
            pkgs.gamemode
          ];
        })
      ];

      programs = {
        gamemode.enable = true;
        gamescope.enable = true;
      };
    };
  };
}
