{
  den.default.homeManager =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      imprint-nvim = pkgs.vimUtils.buildVimPlugin {
        pname = "imprint.nvim";
        version = "2026-02-15";
        src = pkgs.fetchFromGitHub {
          owner = "glyccogen";
          repo = "imprint.nvim";
          rev = "b85cb42bdeee3a3a78ec395a67c8fba2bbc73826";
          hash = "sha256-zXnjX3vOjAtaOvfh1u9sGF2LDdWxvskqtzrkcD8yr4I=";
        };
      };

      playwright-browsers = pkgs.playwright-driver.browsers.override {
        withFirefox = false;
        withWebkit = false;
        withFfmpeg = false;
      };

      # imprint.nvim pip-installs playwright and downloads chromium into this
      # venv unless the marker file exists; pre-seed it with nix instead
      imprint-venv = pkgs.runCommand "imprint-venv" { } ''
        mkdir -p $out/bin
        ln -s ${pkgs.python3.withPackages (ps: [ ps.playwright ])}/bin/python $out/bin/python
        touch $out/.deps_installed
      '';
    in
    {
      xdg.enable = lib.mkDefault true;

      xdg.configFile."nvim" = {
        recursive = true;
        source = ../../nvim;
      };

      # Store paths of nix-built plugins, loaded by lazy specs via `dir`
      xdg.configFile."nvim/lua/nix-paths.lua".text = ''
        return {
          ["imprint.nvim"] = "${imprint-nvim}",
          ["playwright-browsers"] = "${playwright-browsers}",
        }
      '';

      xdg.dataFile."nvim/imprint.nvim/venv".source = imprint-venv;

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
          lazy-nvim
        ];
      };
    };
}
