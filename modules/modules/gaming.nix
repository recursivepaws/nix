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
        steam = {
          enable = true;
          remotePlay.openFirewall = true;
          dedicatedServer.openFirewall = true;
          localNetworkGameTransfers.openFirewall = true;
        };

        gamemode.enable = true;
        gamescope.enable = true;
      };
    };
  };
}
