{
  den.aspects.dj = {
    nixos =
      { pkgs, ... }:
      {
        # Mixxx's udev rule grants non-root hidraw access to the DDJ-FLX4
        services.udev.packages = [ pkgs.mixxx ];
        # JACK backend, so Mixxx doesn't fight pipewire for exclusive hw access
        services.pipewire.jack.enable = true;
      };

    homeManager =
      { pkgs, ... }:
      {
        # QT_QPA_PLATFORMTHEME=gtk3 makes Mixxx abort.
        # TODO: maybe fix upstream?
        home.packages = [
          (pkgs.symlinkJoin {
            name = "mixxx-${pkgs.mixxx.version}";
            paths = [ pkgs.mixxx ];
            nativeBuildInputs = [ pkgs.makeWrapper ];
            postBuild = ''
              wrapProgram $out/bin/mixxx --prefix XDG_DATA_DIRS : \
                "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}:${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}"
            '';
          })
        ];
      };
  };
}
