{ ... }:
{
  den.aspects.syncthing = {
    nixos = _: {
      services.syncthing = {
        enable = true;
        user = "vera";
        group = "users";
        # Default folder lands at ~/Sync; config/keys at ~/.config/syncthing.
        dataDir = "/home/vera";
        configDir = "/home/vera/.config/syncthing";
        openDefaultPorts = true;
        # Anything paired through the web UI at http://127.0.0.1:8384 survives a
        # rebuild while these stay false.
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
              # .obsidian holds home-manager-managed files that are read-only
              # symlinks into the store, so syncthing can't write them.
              ignorePatterns = [ ".obsidian" ];
            };
          };
        };
      };
    };
  };
}
