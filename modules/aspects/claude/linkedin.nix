{ den, ... }:
{
  # Pulled in by claude.nix for the vera user; mcp-servers options come from there.
  den.aspects.linkedin = {
    homeManager =
      { pkgs, ... }:
      let
        # Run uvx from $HOME so project configs can't interfere.
        uvxFromHome = pkgs.writeShellScript "uvx-from-home" ''
          cd "$HOME"
          exec ${pkgs.uv}/bin/uvx "$@"
        '';
      in
      {
        # HACK: needs fastmcp 4 and mcp 2, which nixpkgs lacks, so uvx rather than a store build.
        # Deps land in ~/.cache/uv on first launch; wheels rely on nix-ld.
        # Login session lives in ~/.linkedin-mcp; first tool call opens a login window.
        mcp-servers.settings.servers.linkedin = {
          command = "${uvxFromHome}";
          args = [
            "mcp-server-linkedin@4.28.0"
            # Patchright's downloaded Chromium is not built for NixOS; use the system Chrome.
            "--chrome-path"
            "${pkgs.google-chrome}/bin/google-chrome-stable"
          ];
          env = {
            UV_PYTHON = "${pkgs.python313}/bin/python3";
            UV_PYTHON_DOWNLOADS = "never";
            UV_HTTP_TIMEOUT = "300";
            # nixpkgs python ignores nix-ld, so manylinux wheels (greenlet) need libstdc++ here.
            LD_LIBRARY_PATH = "${pkgs.stdenv.cc.cc.lib}/lib";
          };
        };
      };
  };
}
