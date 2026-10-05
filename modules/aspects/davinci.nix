{ ... }:
{
  den.aspects.davinci = {
    homeManager =
      { pkgs, ... }:
      {
        # Resolve bundles Qt5 without a wayland platform plugin, so it dies
        # silently under the session-wide QT_QPA_PLATFORM=wayland set in niri.nix.
        # https://github.com/NixOS/nixpkgs/issues/341634
        home.packages = [
          (pkgs.symlinkJoin {
            name = "davinci-resolve-studio-xcb";
            paths = [ pkgs.davinci-resolve-studio ];
            nativeBuildInputs = [ pkgs.makeWrapper ];
            postBuild = ''
              for bin in $out/bin/*; do
                wrapProgram "$bin" --set QT_QPA_PLATFORM xcb
              done
            '';
          })
        ];
      };
  };
}
