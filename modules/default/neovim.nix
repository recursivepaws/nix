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

      # npm-only; the package-lock.json is fetched hash-pinned from stalled nixpkgs PR 479030.
      # If that URL dies, regenerate the lock with `npm install --package-lock-only` and vendor it.
      gh-actions-language-server = pkgs.buildNpmPackage {
        pname = "gh-actions-language-server";
        version = "0.0.3";
        src = pkgs.fetchzip {
          url = "https://registry.npmjs.org/gh-actions-language-server/-/gh-actions-language-server-0.0.3.tgz";
          hash = "sha256-vTRClb1oyqH1u4Rvqu9xoCNcWeMBn9aIZ6Vj1sZYcrY=";
        };
        postPatch = ''
          cp ${
            pkgs.fetchurl {
              url = "https://raw.githubusercontent.com/NixOS/nixpkgs/10e4b07a6b0bc97c69eb47db2a6fe869161ea05f/pkgs/by-name/gh/gh-actions-language-server/package-lock.json";
              hash = "sha256-1K5wPw237piARGhF447+1tdqIRSOBmui4LtjlSILlpM=";
            }
          } package-lock.json
        '';
        npmDepsHash = "sha256-mu4ZmokeQzQMRzDobMzXkdAlOTNm/ahHYERi1n+By3c=";
        dontNpmBuild = true;
      };

      # Merges the plugin with the nix-built grammars so queries and parsers move in lockstep.
      treesitter = pkgs.symlinkJoin {
        name = "nvim-treesitter-with-parsers";
        paths =
          let
            ts = pkgs.vimPlugins.nvim-treesitter.withPlugins (
              p: with p; [
                bash
                json
                lua
                swift
                markdown
                markdown_inline
                toml
                yaml
                kdl
                sql
                wgsl
                glsl
                xml
                ssh_config
                rust
                regex
                python
                perl
                # Without vim, cmdline and docs might break
                vim
                # Required for getting most of the `todo-comments` working
                comment
                graphql
                gitattributes
                gitcommit
                gitignore
                git_config
                git_rebase
                dockerfile
                csv
                nix
                astro
                css
                scss
                go
                html
                javascript
                jsdoc
                php
                styled
                tsx
                typescript
                typst
                # snacks.image rendering in docs
                latex
                svelte
                vue
              ]
            );
          in
          [ ts ] ++ ts.dependencies;
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
          ["nvim-treesitter"] = "${treesitter}",
          ["lazy.nvim"] = "${pkgs.vimPlugins.lazy-nvim}",
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
          nixfmt
          rust-analyzer
          file
          trash-cli
          stylua
          lua-language-server
          sqlite
          tectonic

          # LSPs (was mason)
          basedpyright
          ruff
          wgsl-analyzer
          bash-language-server
          awk-language-server
          # bin: docker-langserver
          dockerfile-language-server
          tombi
          nil
          tinymist
          zls
          # html/css/json/eslint servers
          vscode-langservers-extracted
          # bin: tsgo; project-local wins via pnpm_or_path
          typescript-go
          biome
          yaml-language-server
          gh-actions-language-server

          # formatters (was mason); prettier is fallback, project pnpm wins
          prettier
          shfmt
          typstyle

          # DAP (was mason-nvim-dap)
          delve
          # bin: codelldb
          vscode-extensions.vadimcn.vscode-lldb.adapter

        ];

        # snacks.image needs ghostscript's gs, but git-spice shadows it on the profile PATH.
        # extraPackages only suffix PATH, so prefix instead.
        extraWrapperArgs = [
          "--prefix"
          "PATH"
          ":"
          "${pkgs.ghostscript}/bin"
          # snacks frecency loads libsqlite3 via ffi, PATH alone not enough
          "--prefix"
          "LD_LIBRARY_PATH"
          ":"
          "${pkgs.sqlite.out}/lib"
        ];
      };
    };
}
