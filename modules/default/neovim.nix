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

      # npm-only, not in nixpkgs. Upstream has no package-lock.json (bun repo),
      # so a generated one is vendored next to this file. To bump: update both
      # hashes, regenerate the lock from the tarball's package.json with
      # `npm install --package-lock-only --ignore-scripts`.
      gh-actions-language-server = pkgs.buildNpmPackage {
        pname = "gh-actions-language-server";
        version = "0.0.3";
        src = pkgs.fetchzip {
          url = "https://registry.npmjs.org/gh-actions-language-server/-/gh-actions-language-server-0.0.3.tgz";
          hash = "sha256-vTRClb1oyqH1u4Rvqu9xoCNcWeMBn9aIZ6Vj1sZYcrY=";
        };
        postPatch = ''
          cp ${./gh-actions-language-server.package-lock.json} package-lock.json
        '';
        npmDepsHash = "sha256-5vx3+WtRRB1k0KJRKWee74wMOiwMit8u9l1TpVuHZjE=";
        dontNpmBuild = true;
      };

      # Rebuilds the nirukta tree-sitter parser when the grammar source is newer than the compiled .so, run on every nvim start by the nirukta lazy spec.
      # The toolchain is baked in because tree-sitter generate shells out to node and the nirukta devshell's nvim wrapper bypasses extraPackages.
      nirukta-ts-build = pkgs.writeShellApplication {
        name = "nirukta-ts-build";
        runtimeInputs = with pkgs; [
          tree-sitter
          nodejs
          gcc
        ];
        text = ''
          cd "$1"
          if [ grammar.js -nt src/parser.c ]; then
            tree-sitter generate
          fi
          if [ ! -e parser/nirukta.so ] || [ src/parser.c -nt parser/nirukta.so ]; then
            mkdir -p parser
            cc -shared -fPIC -O2 -I src src/parser.c -o parser/nirukta.so
          fi
        '';
      };
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
          ["nirukta-ts-build"] = "${nirukta-ts-build}/bin/nirukta-ts-build",
        }
      '';

      xdg.dataFile."nvim/imprint.nvim/venv".source = imprint-venv;

      programs.neovim = {
        enable = true;
        defaultEditor = true;

        viAlias = true;
        vimAlias = true;
        vimdiffAlias = true;
        withRuby = false;
        withPython3 = false;
        initLua = lib.mkBefore (lib.fileContents ../../nvim/init.lua);

        extraPackages = with pkgs; [

          # TODO: fix nvim building without these
          gcc
          gnumake
          # TODO: end

          nixfmt
          rust-analyzer
          file
          trash-cli
          luarocks
          stylua
          tree-sitter
          # nodejs_22
          lua-language-server
          lua5_1
          lua51Packages.tree-sitter-cli

          # LSPs (was mason)
          basedpyright
          ruff
          wgsl-analyzer
          bash-language-server
          awk-language-server
          dockerfile-language-server # bin: docker-langserver
          tombi
          nil
          tinymist
          zls
          vscode-langservers-extracted # html/css/json/eslint servers
          typescript-go # bin: tsgo; project-local wins via pnpm_or_mason
          biome
          yaml-language-server
          gh-actions-language-server

          # formatters (was mason); prettier is fallback, project pnpm wins
          prettier
          shfmt
          typstyle

          # DAP (was mason-nvim-dap)
          delve
          vscode-extensions.vadimcn.vscode-lldb.adapter # bin: codelldb

        ];

        # snacks.image PDF render wants ghostscript's `gs`, but git-spice in the
        # user profile shadows it; extraPackages only suffix PATH, so prefix
        extraWrapperArgs = [
          "--prefix"
          "PATH"
          ":"
          "${pkgs.ghostscript}/bin"
        ];
        plugins = with pkgs.vimPlugins; [
          lazy-nvim
        ];
      };
    };
}
