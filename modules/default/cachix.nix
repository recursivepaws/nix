let
  # Personal cachix cache - every host pushes what it builds, all hosts pull.
  cache = "recursivepaws";
  publicKey = "recursivepaws.cachix.org-1:TOIUVFStMLMVHRQxs0+Sv5qzJMNMOO0KdubeaDWGCVs=";
  socket = "/run/cachix-daemon/daemon.sock";
in
{
  den.default.nixos =
    {
      pkgs,
      config,
      ...
    }:
    {
      environment.systemPackages = [ pkgs.cachix ];

      nix.settings.substituters = [ "https://${cache}.cachix.org" ];
      nix.settings.trusted-public-keys = [ publicKey ];

      age.secrets.cachix-token = {
        file = ../../secrets/cachix-token.age;
        owner = "root";
        group = "secrets";
        mode = "0440";
      };

      # NOTE: replaces cachix-watch-store, which has no exclude flag and kept dying on davinci-resolve-studio (14.21 GiB, 32 pushes in 5h, never finished).
      # Hook only enqueues over the socket so builds never block; the daemon serializes uploads and skips paths already in the cache.
      nix.settings.post-build-hook = pkgs.writeShellScript "cachix-enqueue" ''
        set -f
        paths=
        for p in $OUT_PATHS; do
          case $p in
            *-davinci-resolve*) ;;
            *) paths="$paths $p" ;;
          esac
        done
        [ -n "$paths" ] || exit 0
        ${pkgs.coreutils}/bin/timeout 5 ${pkgs.cachix}/bin/cachix daemon push --socket ${socket} $paths \
          || echo "cachix daemon unavailable, built outputs not queued" >&2
      '';

      # PERF: -j 1 with 256MiB chunks so a home uplink is not split 8 ways into chunks that outlive the 1h presigned-URL expiry.
      systemd.services.cachix-daemon = {
        description = "Cachix push daemon for ${cache}";
        wantedBy = [ "multi-user.target" ];
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
        serviceConfig = {
          RuntimeDirectory = "cachix-daemon";
          RuntimeDirectoryMode = "0700";
          LoadCredential = [ "cachix-token:${config.age.secrets.cachix-token.path}" ];
          KillSignal = "SIGINT";
          Restart = "on-failure";
          RestartSec = "30s";
        };
        script = ''
          export CACHIX_AUTH_TOKEN="$(<"$CREDENTIALS_DIRECTORY/cachix-token")"
          exec ${pkgs.cachix}/bin/cachix daemon run --socket ${socket} --no-remote-stop -j 1 -s 268435456 ${cache}
        '';
      };
    };
}
