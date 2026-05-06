{ den, ... }:
{
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
        services.caddy = {
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

        # 3. Tailscale: permit Caddy to manage TLS certs via Tailscale
        # (if you want HTTPS on your tailnet via the Caddy+Tailscale integration)
        services.tailscale.permitCertUid = "caddy";

        # Optional: run caddy trust automatically after service starts
        systemd.services.caddy-trust = {
          description = "Trust Caddy local CA";
          after = [ "caddy.service" ];
          wants = [ "caddy.service" ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            Environment = [
              "HOME=/root"
              "PATH=${pkgs.p11-kit}/bin:${pkgs.nssTools}/bin:${pkgs.caddy}/bin"
            ];
            ExecStart = "${pkgs.caddy}/bin/caddy trust";
          };
        };
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
        nodejs =
          let
            version = "20.19.2";
          in
          pkgs.nodejs_20.overrideAttrs (old: {
            version = version;
            src = pkgs.fetchurl {
              url = "https://nodejs.org/dist/v${version}/node-v${version}.tar.xz";
              sha256 = "sha256-Sn/2EdUYD05CAgT6byL5+d6yrF6YYZ3ZpN6H7fWwO24=";
            };
          });
      in
      {
        home = {
          sessionVariables = {
            JAVA_HOME = "${pkgs.openjdk}";
            CPPFLAGS = "-I${pkgs.openjdk}/include";
          };

          packages = with pkgs; [
            nodejs
            pnpm

            # Dev workflow
            git-spice # Stacked PRs
            tilt # Local dev orchestration (Docker Compose)
            _1password-cli # Secrets management
            autossh
            fzf

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
