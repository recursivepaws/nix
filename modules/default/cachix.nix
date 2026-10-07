let
  # Personal cachix cache — every host pushes what it builds, all hosts pull.
  cache = "recursivepaws";
  publicKey = "recursivepaws.cachix.org-1:TOIUVFStMLMVHRQxs0+Sv5qzJMNMOO0KdubeaDWGCVs=";
in
{
  den.default.nixos =
    { pkgs, config, ... }:
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

      # A single long-lived watcher instead of a post-build-hook.
      #
      # nix runs post-build-hook synchronously and blocks the build loop, so an
      # inline push stalls a cold-cache rebuild for the length of a multi-GB
      # upload. Detaching each push fixed the stall but not the duplication: the
      # hook fires once per built derivation, each push walks the full closure,
      # and `cachix push` computes its missing-paths set once at startup — so
      # overlapping invocations can't see each other's in-flight uploads and
      # re-send the same path (observed: wine-rekordbox, 779 MiB, twice in one
      # rebuild). watch-store is one process with one view of the store, so
      # there is nothing to race against and no closure re-walking.
      #
      # Tradeoff: watch-store pushes every path newly added to the store, not
      # only locally built ones. cachix skips paths available on cache.nixos.org,
      # but not ones substituted from the other caches in substitutions.nix
      # (nix-community, niri, noctalia, jake0x539) — those can get mirrored into
      # our cache. Accepted: cheaper than the duplicate-upload races.
      #
      # cachixTokenFile must hold the bare token — the module reads the whole
      # file as the value, so no CACHIX_AUTH_TOKEN= prefix.
      services.cachix-watch-store = {
        enable = true;
        cacheName = cache;
        cachixTokenFile = config.age.secrets.cachix-token.path;
      };
    };
}
