{ inputs, den, ... }:
{
  flake-file.inputs.monarch-mcp-server = {
    url = "github:robcerda/monarch-mcp-server";
    flake = false;
  };

  den.aspects.monarch = {
    # The MCP server registration below lands in the same home-manager option
    # set that claude.nix configures, so that module has to be imported.
    includes = [ den.aspects.claude ];

    homeManager =
      { pkgs, ... }:
      let
        # The project caps itself at <3.14 and pkgs.python3 is already 3.14.
        python = pkgs.python313;
        py = python.pkgs;

        # Neither of the next two is in nixpkgs: oathtool is jaraco's pure-Python TOTP generator.
        # monarchmoneycommunity is the maintained fork of the Monarch API client the MCP server is built on.
        oathtool = py.buildPythonPackage rec {
          pname = "oathtool";
          version = "2.4.0";
          pyproject = true;
          src = py.fetchPypi {
            inherit pname version;
            hash = "sha256-Q8DcFD2N30gF8LAAqK94ZhpID4R/ZHxsxAO0B9lnETg=";
          };
          build-system = with py; [
            setuptools
            setuptools-scm
          ];
          dependencies = with py; [
            autocommand
            path
          ];
          # Test extra pulls pytest-checkdocs/pytest-ruff, neither packaged.
          doCheck = false;
          pythonImportsCheck = [ "oathtool" ];
        };

        monarchmoneycommunity = py.buildPythonPackage rec {
          pname = "monarchmoneycommunity";
          version = "1.6.0";
          format = "wheel";
          src = py.fetchPypi {
            inherit pname version format;
            dist = "py3";
            python = "py3";
            hash = "sha256-MDSIR6cjeEU6ZdrQ5QSnfe/smYEoMte9T2kzY5FcKbM=";
          };
          dependencies = with py; [
            aiohttp
            gql
            oathtool
          ];
          # Imported under its original name, not the distribution name.
          pythonImportsCheck = [ "monarchmoney" ];
        };

        monarch-mcp-server = py.buildPythonApplication {
          pname = "monarch-mcp-server";
          version = "0.1.0-unstable-2026-10-12";
          pyproject = true;
          src = inputs.monarch-mcp-server;
          build-system = [ py.setuptools ];
          dependencies = with py; [
            mcp
            monarchmoneycommunity
            gql
            keyring
            python-dotenv
            pydantic
          ];
          # Suite is unit-only but wants pytest-asyncio config we don't carry.
          doCheck = false;
          pythonImportsCheck = [ "monarch_mcp_server.server" ];
          # login_setup.py lives at the repo root and is not part of the
          # package, but it is the only non-interactive-client way to sign in.
          postInstall = ''
            install -Dm555 login_setup.py $out/bin/monarch-login
          '';
        };
      in
      {
        mcp-servers.settings.servers.monarch = {
          command = "${monarch-mcp-server}/bin/monarch-mcp-server";
          # Read-only by default: the write tools (create/update/delete
          # transactions, rules, budgets, goals) are not registered at all.
          env.MONARCH_MCP_READ_ONLY = "1";
        };

        # One-time interactive login; the session lands in gnome-keyring.
        home.packages = [ monarch-mcp-server ];
      };
  };
}
