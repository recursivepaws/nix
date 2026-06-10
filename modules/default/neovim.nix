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

        nixfmt
        luarocks
        stylua
        tree-sitter
        # nodejs_22
        lua-language-server
        lua5_1
        lua51Packages.tree-sitter-cli
      ];
    };

  den.default.homeManager =
    { pkgs, config, ... }:
    let
      snapLibs = with pkgs; [
        nss
        nspr
        atk
        at-spi2-atk
        libxkbcommon
        libx11
        libxcb
        libxext
        libxfixes
        libgbm
        libxdamage
        libxrandr
        libxcomposite
        alsa-lib
        glib
        dbus
        expat
      ];
      neovim-wrapped = pkgs.symlinkJoin {
        name = "neovim";
        paths = [ pkgs.neovim ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/nvim \
            --prefix PATH : "${pkgs.gcc13}/bin" \
            --prefix LD_LIBRARY_PATH : "${pkgs.lib.makeLibraryPath snapLibs}"
        '';
      };
    in
    {
      home.packages = [
        neovim-wrapped
      ];
    };
}
