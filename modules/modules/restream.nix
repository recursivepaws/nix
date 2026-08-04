{
  den.aspects.restream = {
    homeManager =
      { pkgs, lib, ... }:
      {
        # reMarkable screen sharing over SSH (https://github.com/rien/reStream).
        # The nixpkgs package wraps ffplay, lz4, ssh, and nc onto PATH.
        home.packages = [ pkgs.restream ];

        xdg.desktopEntries = {
          restream-horizontal = {
            name = "Remarkable Stream (horizontal)";
            comment = "Stream the reMarkable screen with ffplay in landscape";
            exec = "${lib.getExe pkgs.restream} -t 'Remarkable Stream (horizontal)'";
            terminal = false;
            type = "Application";
            categories = [ "Utility" ];
          };
          restream-vertical = {
            name = "Remarkable Stream (vertical)";
            comment = "Stream the reMarkable screen with ffplay in portrait";
            exec = "${lib.getExe pkgs.restream} -p -t 'Remarkable Stream (vertical)'";
            terminal = false;
            type = "Application";
            categories = [ "Utility" ];
          };
        };
      };
  };
}
