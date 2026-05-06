{
  den.default.nixos =
    { config, pkgs, ... }:
    {
      programs.neovim = {
        enable = true;
        defaultEditor = true;
      };

      environment.systemPackages = with pkgs; [
        # TODO: fix nvim building without these
        gcc
        gnumake
        # TODO: end

        nixfmt-rfc-style
        luarocks
        lua5_1
        stylua
        tree-sitter
        nodejs_22
        lua-language-server
      ];
    };

  den.default.homeManager =
    { pkgs, config, ... }:
    {
      home.packages = with pkgs; [
        neovim
      ];
    };
}
