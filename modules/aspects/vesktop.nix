{
  # NOTE: nice reference https://github.com/nyxar77/homeconfig/blob/15ce1d4d2ee505b0701c34c0b59972146561c9fc/home/modules/apps/vesktop.nix
  den.aspects.vesktop = {
    homeManager = { }: {
      programs.vesktop = {
        enable = true;
        settings = {
          # arRPC = true;
          checkUpdates = false;
        };
      };

      # vencord.themes = {}
    };
  };
}
