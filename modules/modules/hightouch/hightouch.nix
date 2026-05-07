{ den, inputs, ... }:
{
  flake-file.inputs.nixpkgs-node.url = "github:NixOS/nixpkgs/b95255df2360a45ddbb03817a68869d5cb01bf96";

  den.aspects.hightouch = {
    includes = [ den.aspects.kubernetes ];
    nixos =
      {
        pkgs,
        config,
        user,
        ...
      }:
      {
        environment.systemPackages = with pkgs; [
          # Core CLI tools
          git
          jq
          caddy
          unixodbc

          # Runtimes & languages
          go
          openjdk
          python3

          # Database
          postgresql_15
        ];

        # Required by tilt
        virtualisation.docker.enable = true;

        security.pki.certificateFiles = [
          (pkgs.fetchurl {
            url = "https://ht-dev-agents-assets.s3.us-west-2.amazonaws.com/hightouch-development-root.cer";
            hash = "sha256-yRYHTdTico/Zd1uwAho4CG+TnmeEyJ2vJEEGAf7bxVQ=";
          })
        ];

        services.tailscale = {
          enable = true;
        };
        networking.nftables.enable = true;
        networking.firewall = {
          enable = true;
          trustedInterfaces = [ "tailscale0" ];
          allowedUDPPorts = [ config.services.tailscale.port ];
          checkReversePath = "loose";
        };

        # Force tailscaled to use nftables instead of iptables compat layer
        systemd.services.tailscaled.serviceConfig.Environment = [
          "TS_DEBUG_FIREWALL_MODE=nftables"
        ];
      };

    homeManager =
      {
        pkgs,
        config,
        lib,
        ...
      }:
      let
        # The specific version of node pinned in `pnpm-workspace.yaml`
        nodejs = inputs.nixpkgs-node.legacyPackages.${pkgs.system}.nodejs_20;

        # nodejs =
        # let
        #   version = "20.19.2";
        # in
        # pkgs.nodejs_20.overrideAttrs (old: {
        #   version = version;
        #   src = pkgs.fetchurl {
        #     url = "https://nodejs.org/dist/v${version}/node-v${version}.tar.xz";
        #     sha256 = "sha256-Sn/2EdUYD05CAgT6byL5+d6yrF6YYZ3ZpN6H7fWwO24=";
        #   };
        # });
      in
      {
        home = {
          sessionVariables = {
            JAVA_HOME = "$HOME/.java-home";
            CPPFLAGS = "-I${pkgs.openjdk}/lib/openjdk/include";
            JAVA_TOOL_OPTIONS = "-Djavax.net.ssl.trustStore=$HOME/.java/cacerts";
          };

          activation.setupJavaCacerts = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            $DRY_RUN_CMD mkdir -p "$HOME/.java"
            $DRY_RUN_CMD cp --no-preserve=mode \
              ${pkgs.openjdk}/lib/openjdk/lib/security/cacerts \
              "$HOME/.java/cacerts"
            $DRY_RUN_CMD chmod 644 "$HOME/.java/cacerts"

            # Mirror the openjdk tree with a writable cacerts
            $DRY_RUN_CMD rm -rf "$HOME/.java-home"
            $DRY_RUN_CMD cp -r --no-preserve=mode \
              ${pkgs.openjdk}/lib/openjdk \
              "$HOME/.java-home"
            $DRY_RUN_CMD chmod -R u+w "$HOME/.java-home"
            $DRY_RUN_CMD ln -sf "$HOME/.java/cacerts" "$HOME/.java-home/lib/security/cacerts"
          '';
          # sessionVariables = {
          #   JAVA_HOME = "${pkgs.openjdk}";
          #   CPPFLAGS = "-I${pkgs.openjdk}/include";
          #   JAVA_TOOL_OPTIONS = "-Djavax.net.ssl.trustStore=$HOME/.java/cacerts";
          # };
          #
          # activation.setupJavaCacerts = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          #   $DRY_RUN_CMD mkdir -p "$HOME/.java"
          #   $DRY_RUN_CMD cp --no-preserve=mode \
          #     ${pkgs.openjdk}/lib/openjdk/lib/security/cacerts \
          #     "$HOME/.java/cacerts"
          #   $DRY_RUN_CMD chmod 644 "$HOME/.java/cacerts"
          #   $DRY_RUN_CMD ln -sf "$HOME/.java/cacerts" "$HOME/.keystore"
          # '';

          shellAliases = {
            open = "xdg-open";
          };

          packages = with pkgs; [
            nodejs
            (pkgs.pnpm.override { nodejs = nodejs; })

            # `open` command
            xdg-utils

            # Dev workflow
            git-spice # Stacked PRs
            tilt # Local dev orchestration (Docker Compose)
            _1password-cli # Secrets management
            autossh
            fzf
            nssTools

            # Python tooling
            pipx
            # python312
            python312Packages.setuptools # python-setuptools
            # libomp # OpenMP for LightGBM
          ];
        };
      };
  };
}
