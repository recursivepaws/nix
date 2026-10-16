{ inputs, ... }:
{
  # 24.18.0
  flake-file.inputs.nixpkgs-node.url = "github:NixOS/nixpkgs/a47c123a609287a012dfc44d281de2dd4ed13394";

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
          tmux

          # Infra
          terraform
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
          # Container->host TCP is dropped by the INPUT chain, so Caddy 503s on app./api.local.hightouch.dev and tilt.local never connects.
          # Matched on source IP because Compose bridges are named br-<network-id>; add 8000 (destinations) / 3001 (agent-runtime) if those ever run on the host.
          extraInputRules = ''
            ip saddr 172.16.0.0/12 tcp dport { 3000, 5000, 10350 } accept
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
        # The node version pinned in `pnpm-workspace.yaml`.
        # Taken from the nixpkgs-node input rather than an overlay, so the main package set keeps its cache hits.
        nodePkgs = inputs.nixpkgs-node.legacyPackages.${pkgs.stdenv.hostPlatform.system};
        nodejs = nodePkgs.nodejs_24;
        pnpm = nodePkgs.pnpm.override { nodejs-slim = nodePkgs.nodejs-slim_24; };

        # Lets the backend's JVM tooling trust custom CAs.
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

        # Trusts Caddy's local root cert in the NSS database, then restarts Chrome to pick up the new anchor.
        # Fingerprint-gated so Chrome is not killed on every caddy container start.
        caddyTrustScript = pkgs.writeShellScriptBin "caddy-trust" ''
          set -euo pipefail

          FINGERPRINT_FILE="$HOME/.local/share/caddy-trust/cert.sha256"
          mkdir -p "$(dirname "$FINGERPRINT_FILE")"

          CERT_TMP=$(mktemp /tmp/caddy-local-root.XXXXXX.crt)
          trap 'rm -f "$CERT_TMP"' EXIT

          # Fetch and validate in one step - probing API readiness separately races the fetch.
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
          # Chrome reads the sqlite NSS db (cert9.db) under sql:, which does not exist until Chrome has run once.
          NSSDB="$HOME/.pki/nssdb"
          mkdir -p "$NSSDB"
          if [ ! -f "$NSSDB/cert9.db" ]; then
            ${pkgs.nssTools}/bin/certutil -N -d "sql:$NSSDB" --empty-password
          fi
          # Remove stale entry first so repeated volume wipes don't accumulate
          # duplicate "Caddy Local Authority" certs in the NSS database.
          ${pkgs.nssTools}/bin/certutil -D \
            -n "Caddy Local Authority" \
            -d "sql:$NSSDB" 2>/dev/null || true
          ${pkgs.nssTools}/bin/certutil -A \
            -n "Caddy Local Authority" \
            -t "CT,," \
            -i "$CERT_TMP" \
            -d "sql:$NSSDB"
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

        # `docker events` rather than polling, so this is idle-free when nothing is happening.
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
              ${lib.getExe caddyTrustScript} || echo "caddy-trust-watcher: trust script failed, continuing"
            done
        '';
      in
      {
        home = {
          sessionVariables = {
            JAVA_HOME = "$HOME/.java-home";
            CPPFLAGS = "-I${pkgs.openjdk}/lib/openjdk/include";
            JAVA_TOOL_OPTIONS = "-Djavax.net.ssl.trustStore=$HOME/.java/cacerts";

            # Tilt is global per machine and pinned to whichever directory started it, and the compose project name is that directory's basename - hardcoded above as `hightouch-caddy-1`.
            # WARN: starting compose from a worktree renames the container silently and the watcher never fires, so keep this checkout on master and do ticket work in worktrees.
            HIGHTOUCH_ROOT = "${config.home.homeDirectory}/Software/hightouch";
            # Same value under the name .cursor/copy-worktree-secrets.sh requires.
            ROOT_WORKTREE_PATH = "${config.home.homeDirectory}/Software/hightouch";
          };

          activation.setupJavaCacerts = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            ${setupJavaCacertsScript}
          '';

          shellAliases = {
            open = "xdg-open";
          };

          packages = [
            nodejs
            pnpm
            caddyTrustScript
          ]
          ++ (with pkgs; [
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
          ]);
        };

        programs.zsh.initContent = ''
          export LD_LIBRARY_PATH="${pkgs.unixodbc}/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
        '';

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
