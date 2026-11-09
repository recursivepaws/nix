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
        config,
        lib,
        user ? null,
        ...
      }:
      let
        # barkstation keeps its copies on the NAS; desktops keep them in ~.
        at =
          name: home:
          if config.networking.hostName == "barkstation" then "/mnt/data/syncthing/${name}" else home;
      in
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
              amanita.id = "ZJDVRK5-NEM2NJS-MKOBW5I-MOEA7GE-BTCJHGP-5B2XWIF-G5QCMOE-HLA37AM";
              # Always-on hub, so desktops sync through it while the others are off.
              barkstation.id = "JRODUYS-KUN67Q2-JH4VARM-4PA43VD-25JJRZJ-ZZ7SQJ4-S4FSTSA-7D7PNAJ";
            };

            # Declare a folder only on hosts in its device list, so unrelated folders never get created in that user's home.
            folders =
              lib.mapAttrs
                (
                  # Synology's indexer drops @eaDir into every directory on the NAS copies.
                  _: f: f // { ignorePatterns = (f.ignorePatterns or [ ]) ++ [ "@eaDir" ]; }
                )
                (
                  lib.filterAttrs (_: f: builtins.elem config.networking.hostName f.devices) {
                    beets = {
                      path = at "beets" "~/Music/beets";
                      devices = [
                        "hericium"
                        "ampulex"
                        "barkstation"
                        "amanita"
                      ];
                    };
                    playlists = {
                      path = at "playlists" "~/Music/playlists";
                      devices = [
                        "hericium"
                        "ampulex"
                        "barkstation"
                        "amanita"
                      ];
                    };
                    notes = {
                      path = at "notes" "~/Documents/notes";
                      devices = [
                        "hericium"
                        "ampulex"
                        "barkstation"
                      ];
                      # .obsidian holds home-manager-managed store symlinks, which syncthing can't write.
                      ignorePatterns = [ ".obsidian" ];
                    };
                    # Work's tickets: `~` is work's home on amanita, vera's on hericium (work gets a symlink there, hericium.nix).
                    tickets = {
                      path = at "tickets" "~/Software/tickets";
                      devices = [
                        "amanita"
                        "hericium"
                        "barkstation"
                      ];
                    };
                    # ampulex owns the rekordbox DB; other hosts only mirror it, so their local edits never propagate back.
                    rbxport = {
                      path = at "rbxport" "~/.local/share/rbxport/rekordbox";
                      type = if config.networking.hostName == "ampulex" then "sendonly" else "receiveonly";
                      devices = [
                        "hericium"
                        "ampulex"
                        "barkstation"
                      ];
                    };
                  }
                );
          };
        };
      };
  };
}
