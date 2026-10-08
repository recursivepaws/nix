{ den, ... }:
{
  den.aspects.messaging = {
    homeManager =
      {
        pkgs,
        lib,
        user,
        ...
      }:
      {
        home.packages = with pkgs; [
          telegram-desktop
          signal-desktop
          # discord
          vesktop
          discordchatexporter-desktop
        ];
      }
      // lib.optionalAttrs (user.hasAspect den.aspects.niri) {
        programs.niri.settings.window-rules = [
          {
            matches = [
              { app-id = "^org\\.telegram\\.desktop$"; }
              { app-id = "^com\\.ktechpit\\.whatsie$"; }
              { app-id = "^discord$"; }
              { app-id = "^vesktop$"; }
              { app-id = "^vencord$"; }
              { app-id = "^signal$"; }
            ];
            block-out-from = "screencast";
          }
        ];
      };
  };
}
