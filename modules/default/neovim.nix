{
  # den.default.nixos =
  #   { config, pkgs, ... }:
  #   {
  #     programs.neovim = {
  #       enable = true;
  #       defaultEditor = true;
  #
  #       viAlias = true;
  #       vimAlias = true;
  #
  #       extraPackages = with pkgs; [
  #
  #         # TODO: fix nvim building without these
  #         gcc
  #         gnumake
  #         # TODO: end
  #
  #         nixfmt
  #         luarocks
  #         stylua
  #         tree-sitter
  #         # nodejs_22
  #         lua-language-server
  #         lua5_1
  #         lua51Packages.tree-sitter-cli
  #       ];
  #       plugins = with pkgs.vimPlugins; [
  #         codesnap-nvim
  #       ];
  #     };
  #   };

  den.default.homeManager =
    { pkgs, config, lib, ... }:
    {
      xdg.enable = lib.mkDefault true;

      xdg.configFile."nvim" = {
    recursive = true; source = ../../nvim;
  };

      programs.neovim = {
        enable = true;
        defaultEditor = true;

        viAlias = true;
        vimAlias = true;
        vimdiffAlias = true;
        initLua = lib.mkBefore (lib.fileContents ../../nvim/init.lua);

        extraPackages = with pkgs; [

          # TODO: fix nvim building without these
          gcc
          gnumake
          # TODO: end

          nixfmt
          luarocks
          stylua
          tree-sitter
          # nodejs_22
          lua-language-server
          lua5_1
          lua51Packages.tree-sitter-cli
        ];
        plugins = with pkgs.vimPlugins; [
          codesnap-nvim
        ];
      };
      # home.packages = [ neovim ];
    };
}
