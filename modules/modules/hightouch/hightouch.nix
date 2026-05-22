{ inputs, ... }:
{
  flake-file.inputs.nixpkgs-node.url = "github:NixOS/nixpkgs/b95255df2360a45ddbb03817a68869d5cb01bf96";

  den.aspects.hightouch = {
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
        virtualisation.docker = {
          enable = true;
          # Don't clog up the root partition with images
          daemon.settings = {
            data-root = "/home/docker";
          };
        };

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
          # Allow Docker containers to reach host ports.
          # Without this, container→host TCP is blocked by the INPUT chain —
          # which is why https://tilt.local.hightouch.dev proxies to 172.17.0.1:10350
          # but the connection times out.
          # We match on source IP rather than interface name because Docker Compose
          # networks use dynamically-named bridges (br-<network-id>), not docker0.
          # 172.16.0.0/12 covers the full RFC 1918 range Docker assigns to its networks.
          extraInputRules = ''
            ip saddr 172.16.0.0/12 tcp dport 10350 accept
          '';
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

        #  Allows the Hightouch backend (which uses Java/JVM-based tooling) to trust custom CAs
        setupJavaCacertsScript = pkgs.writeShellScript "setup-java-cacerts" ''
          set -euo pipefail
          mkdir -p "$HOME/.java"
          cp --no-preserve=mode ${pkgs.openjdk}/lib/openjdk/lib/security/cacerts "$HOME/.java/cacerts"
          chmod 644 "$HOME/.java/cacerts"

          # Mirror the openjdk tree with a writable cacerts
          rm -rf "$HOME/.java-home"
          cp -r --no-preserve=mode ${pkgs.openjdk}/lib/openjdk "$HOME/.java-home"
          chmod -R u+w "$HOME/.java-home"
          ln -sf "$HOME/.java/cacerts" "$HOME/.java-home/lib/security/cacerts"
        '';

        # Script that trusts Caddy's local root certificate in the NSS database
        # and restarts Chrome so it picks up the new trust anchor.
        # Only runs when the cert fingerprint has actually changed — avoids
        # needlessly killing Chrome on every caddy container start.
        caddyTrustScript = pkgs.writeShellScript "caddy-trust" ''
          set -euo pipefail

          FINGERPRINT_FILE="$HOME/.local/share/caddy-trust/cert.sha256"
          mkdir -p "$(dirname "$FINGERPRINT_FILE")"

          CERT_TMP=$(mktemp /tmp/caddy-local-root.XXXXXX.crt)
          trap 'rm -f "$CERT_TMP"' EXIT

          # Wait for Caddy to serve a valid root certificate. Fetches and
          # validates in one step to avoid a race between checking API
          # readiness and the actual fetch.
          CERT_READY=false
          for i in $(seq 1 30); do
            if ${pkgs.curl}/bin/curl -sf --max-time 5 http://localhost:2019/pki/ca/local 2>/dev/null \
                | ${pkgs.jq}/bin/jq -re '.root_certificate // empty' \
                > "$CERT_TMP" 2>/dev/null \
               && [ -s "$CERT_TMP" ]; then
              CERT_READY=true
              break
            fi
            echo "caddy-trust: waiting for caddy cert to become available ($i/30)"
            sleep 2
          done

          if [ "$CERT_READY" != "true" ]; then
            echo "caddy-trust: could not fetch root certificate after 30 attempts, giving up" >&2
            exit 1
          fi

          NEW_FINGERPRINT=$(${pkgs.openssl}/bin/openssl x509 -fingerprint -noout -sha256 -in "$CERT_TMP" 2>/dev/null | cut -d= -f2)
          OLD_FINGERPRINT=$(cat "$FINGERPRINT_FILE" 2>/dev/null || true)

          if [ "$NEW_FINGERPRINT" = "$OLD_FINGERPRINT" ]; then
            echo "caddy-trust: cert unchanged ($NEW_FINGERPRINT), nothing to do"
            exit 0
          fi

          echo "caddy-trust: cert changed, re-trusting"
          # Remove stale entry first so repeated volume wipes don't accumulate
          # duplicate "Caddy Local Authority" certs in the NSS database.
          ${pkgs.nssTools}/bin/certutil -D \
            -n "Caddy Local Authority" \
            -d "$HOME/.pki/nssdb" 2>/dev/null || true
          ${pkgs.nssTools}/bin/certutil -A \
            -n "Caddy Local Authority" \
            -t "CT,," \
            -i "$CERT_TMP" \
            -d "$HOME/.pki/nssdb"
          rm "$CERT_TMP"

          echo "$NEW_FINGERPRINT" > "$FINGERPRINT_FILE"
          echo "caddy-trust: trusted new cert ($NEW_FINGERPRINT)"

          echo "caddy-trust: restarting Chrome"
          ${pkgs.procps}/bin/pkill -f "chrome" || true
          sleep 2
          # Launch Chrome in a transient systemd scope so it is detached from
          # this service's cgroup and survives service restarts/rebuilds.
          if command -v google-chrome-stable >/dev/null 2>&1; then
            systemd-run --user --scope --unit=google-chrome \
              google-chrome-stable --restore-last-session >/dev/null 2>&1 &
          elif command -v google-chrome >/dev/null 2>&1; then
            systemd-run --user --scope --unit=google-chrome \
              google-chrome --restore-last-session >/dev/null 2>&1 &
          fi
        '';

        # Watches for caddy container start events and fires caddyTrustScript
        # when the cert changes. Uses `docker events` so it's reactive rather
        # than polling — zero overhead when nothing is happening.
        caddyTrustWatcherScript = pkgs.writeShellScript "caddy-trust-watcher" ''
          set -euo pipefail
          echo "caddy-trust-watcher: listening for hightouch-caddy-1 start events"
          ${pkgs.docker}/bin/docker events \
            --filter "container=hightouch-caddy-1" \
            --filter "event=start" \
            --format "{{.TimeNano}}" \
          | while read -r _line; do
              echo "caddy-trust-watcher: caddy started, waiting for it to initialize"
              sleep 5
              ${caddyTrustScript} || echo "caddy-trust-watcher: trust script failed, continuing"
            done
        '';
      in
      {
        home = {
          sessionVariables = {
            JAVA_HOME = "$HOME/.java-home";
            CPPFLAGS = "-I${pkgs.openjdk}/lib/openjdk/include";
            JAVA_TOOL_OPTIONS = "-Djavax.net.ssl.trustStore=$HOME/.java/cacerts";
          };

          activation.setupJavaCacerts = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            ${setupJavaCacertsScript}
          '';

          shellAliases = {
            open = "xdg-open";
          };

          packages = with pkgs; [
            nodejs
            (pnpm.override { nodejs = nodejs; })

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

        # Watches for the Caddy container to (re)start and re-trusts its local
        # root cert in the NSS database only when the cert has actually changed
        # (i.e. after a volume wipe). Chrome is restarted only in that case.
        systemd.user.services.caddy-trust-watcher = {
          Unit = {
            Description = "Re-trust Caddy local root cert when it changes";
          };
          Service = {
            Type = "simple";
            ExecStart = "${caddyTrustWatcherScript}";
            Restart = "on-failure";
            RestartSec = 5;
          };
          Install = {
            WantedBy = [ "default.target" ];
          };
        };
      };
  };
}
