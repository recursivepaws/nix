let
  # Personal cachix cache - every host pushes what it builds, all hosts pull.
  cache = "recursivepaws";
  publicKey = "recursivepaws.cachix.org-1:TOIUVFStMLMVHRQxs0+Sv5qzJMNMOO0KdubeaDWGCVs=";
in
{
  den.default.nixos =
    {
      pkgs,
      config,
      lib,
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

      # PERF: post-build-hook blocks the build loop and fires per derivation, so closures re-walk and big paths upload twice (wine-rekordbox, 779 MiB, twice in one rebuild).
      # NOTE: watch-store pushes anything new in the store, so paths substituted from substitutions.nix get mirrored into our cache too.
      services.cachix-watch-store = {
        enable = true;
        cacheName = cache;
        # WARN: bare token only - the module reads the whole file as the value.
        cachixTokenFile = config.age.secrets.cachix-token.path;
      };

      # PERF: default -j 8 / -s 32MiB splits a home uplink 8 ways, so chunks hit the 1h presigned-URL expiry and watch-store loops (davinci-resolve-studio, 14.21 GiB, 32 pushes in 5h, never finished).
      # The module takes no extra args, hence mkForce: -j 1 with 256MiB chunks cuts a 14 GiB path from ~455 chunks to ~57.
      systemd.services.cachix-watch-store-agent.script = lib.mkForce ''
        export CACHIX_AUTH_TOKEN="$(<"$CREDENTIALS_DIRECTORY/cachix-token")"
        exec ${pkgs.cachix}/bin/cachix watch-store -j 1 -s 268435456 ${cache}
      '';
    };
}
