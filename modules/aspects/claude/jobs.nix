{ den, ... }:
{
  # Pulled in by claude.nix for the vera user; mcp-servers options come from there.
  den.aspects.jobs = {
    homeManager =
      { pkgs, lib, ... }:
      let
        # Run uvx from $HOME so project configs can't interfere.
        uvxFromHome = pkgs.writeShellScript "uvx-from-home" ''
          cd "$HOME"
          exec ${pkgs.uv}/bin/uvx "$@"
        '';
        # HACK: these need mcp versions nixpkgs lacks, so uvx rather than a store build.
        # Deps land in ~/.cache/uv on first launch; wheels rely on nix-ld.
        uvEnv = {
          UV_PYTHON = "${pkgs.python313}/bin/python3";
          UV_PYTHON_DOWNLOADS = "never";
          UV_HTTP_TIMEOUT = "300";
          # nixpkgs python ignores nix-ld, so manylinux wheels need their libs here
          # (greenlet: libstdc++, numpy: libz).
          LD_LIBRARY_PATH = lib.makeLibraryPath [
            pkgs.stdenv.cc.cc.lib
            pkgs.zlib
          ];
        };
      in
      {
        mcp-servers.settings.servers = {
          # Disabled for now. Login session lives in ~/.linkedin-mcp; first tool call opens a login window.
          # linkedin = {
          #   command = "${uvxFromHome}";
          #   args = [
          #     "mcp-server-linkedin@4.28.0"
          #     # Patchright's downloaded Chromium is not built for NixOS; use the system Chrome.
          #     "--chrome-path"
          #     "${pkgs.google-chrome}/bin/google-chrome-stable"
          #   ];
          #   env = uvEnv;
          # };

          # Indeed, Glassdoor, ZipRecruiter, Google Jobs, LinkedIn (scraped; sites rate-limit).
          jobspy = {
            command = "${uvxFromHome}";
            args = [ "mcp-jobspy@1.4.1" ];
            env = uvEnv;
          };

          # Greenhouse, Lever, Ashby boards via their public job-board APIs.
          ats-jobs = {
            command = "${uvxFromHome}";
            args = [ "ats-jobs-mcp@1.2.0" ];
            env = uvEnv;
          };
        };
      };
  };
}
