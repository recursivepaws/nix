{ inputs, pkgs, ... }: {
  imports = with inputs; [ stylix.nixosModules.stylix ];
  stylix = {
    polarity = "dark";
    targets.gtk.enable = false;
    autoEnable = true;
    base16Scheme = "${pkgs.nightfox-nvim}/extra/carbonfox/base16.yaml";
  };
}
