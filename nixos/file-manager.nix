{ pkgs, ... }: {
  services.gvfs.enable = true;
  services.tumbler.enable = true;

  programs.thunar = {
    enable = true;
    plugins = with pkgs.xfce; [ thunar-volman thunar-archive-plugin ];
  };

  xdg.mime.defaultApplications = { "inode/directory" = "thunar.desktop"; };
}
