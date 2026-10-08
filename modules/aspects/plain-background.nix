{ den, ... }:
{
  # No wallpaper: noctalia's wallpaper engine off, plain black via niri.
  den.aspects.plain-background = {
    homeManager =
      { lib, user, ... }:
      {
        imports =
          lib.optional (user.hasAspect den.aspects.niri) {
            programs.niri.settings.layout.background-color = "#000000";
          }
          ++ lib.optional (user.hasAspect den.aspects.noctalia) {
            programs.noctalia.settings.wallpaper.enabled = false;
          };
      };
  };
}
