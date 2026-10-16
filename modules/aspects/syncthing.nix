{ ... }:
{
  den.aspects.syncthing = {
    # Syncthing litters every synced folder with these.
    homeManager = _: {
      programs.git.ignores = [
        ".stfolder/"
        ".stignore"
      ];
    };

    nixos =
      {
        lib,
        user ? null,
        ...
      }:
      lib.mkIf (user != null) {
        services.syncthing = {
          enable = true;
          user = user.userName;
          group = "users";
          # Default folder lands at ~/Sync; config/keys at ~/.config/syncthing.
          dataDir = "/home/${user.userName}";
          configDir = "/home/${user.userName}/.config/syncthing";
          openDefaultPorts = true;
          # While these stay false, anything paired through the web UI at http://127.0.0.1:8384 survives a rebuild.
          overrideDevices = false;
          overrideFolders = false;

          settings = {
            # Device IDs come from `syncthing --device-id` on each machine.
            devices = {
              hericium.id = "DF42VLZ-AEK3KVC-4LMFQ5F-Z4UECDF-XEKO2X2-NYSOBRA-NUJA5ME-E2ZURA4";
              ampulex.id = "JEN3UBL-IZKUXBJ-3NTN2ER-WYM75SC-ZLDP4DM-VATQNVR-UQVMNBP-TUC6QAC";
            };

            folders = {
              beets = {
                path = "~/Music/beets";
                devices = [
                  "hericium"
                  "ampulex"
                ];
              };
              playlists = {
                path = "~/Music/playlists";
                devices = [
                  "hericium"
                  "ampulex"
                ];
              };
              notes = {
                path = "~/Documents/notes";
                devices = [
                  "hericium"
                  "ampulex"
                ];
                # .obsidian holds home-manager-managed store symlinks, which syncthing can't write.
                ignorePatterns = [ ".obsidian" ];
              };
            };
          };
        };
      };
  };
}
