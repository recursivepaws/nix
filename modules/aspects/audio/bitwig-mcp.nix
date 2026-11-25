{ den, ... }:
{
  # Bitwig MCP over OSC. Needs the DrivenByMoss "Open Sound Control" controller
  # added in Bitwig (Settings > Controllers): receive 8000, send 9000.
  # DOCS: https://github.com/WeModulate/bitwig-mcp-server
  den.aspects.bitwig-mcp =
    {
      user ? null,
      ...
    }:
    {
      homeManager =
        { pkgs, lib, ... }:
        let
          uvxFromHome = pkgs.writeShellScript "uvx-from-home" ''
            cd "$HOME"
            exec ${pkgs.uv}/bin/uvx "$@"
          '';
        in
        # optionalAttrs, not mkIf: mcp-servers options only exist when claude imports mcp-servers-nix.
        lib.optionalAttrs (user != null && user.hasAspect den.aspects.claude) {
          # HACK: not on PyPI and pulls chromadb + sentence-transformers (torch), so uvx from a pinned
          # git rev rather than a store build. First launch downloads several GB into ~/.cache/uv.
          mcp-servers.settings.servers.bitwig = {
            command = "${uvxFromHome}";
            args = [
              "--from"
              "git+https://github.com/WeModulate/bitwig-mcp-server@120f7a0fc01e240657a8a3bc6993557675a37fc0"
              "python"
              "-m"
              "bitwig_mcp_server"
            ];
            env = {
              UV_PYTHON = "${pkgs.python312}/bin/python3";
              UV_PYTHON_DOWNLOADS = "never";
              UV_HTTP_TIMEOUT = "300";
              # nixpkgs python ignores nix-ld, so manylinux wheels need their libs here.
              LD_LIBRARY_PATH = lib.makeLibraryPath [
                pkgs.stdenv.cc.cc.lib
                pkgs.zlib
              ];
            };
          };
        };
    };
}
