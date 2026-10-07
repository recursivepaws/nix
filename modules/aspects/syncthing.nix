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
        # Devices and folders are paired through the web UI at
        # http://127.0.0.1:8384 — leaving these false keeps those edits.
        overrideDevices = false;
        overrideFolders = false;
      };
    };
  };
}
