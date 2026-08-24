{
  den.aspects.file-manager = {
    nixos =
      { pkgs, ... }:
      {
        services.gvfs.enable = true;
        environment.systemPackages = with pkgs; [
          nautilus
          file-roller
        ];
        xdg.mime.defaultApplications = {
          "inode/directory" = "org.gnome.Nautilus.desktop";
        };
      };
  };
}
