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

      # Push every locally-built path. The hook fires only after a real build,
      # so substituted paths never trigger a push.
      #
      # Must be detached: nix runs post-build-hook synchronously and blocks the
      # build loop until it exits, and `cachix push` uploads the full closure of
      # $OUT_PATHS. Pushing inline makes a cold-cache rebuild hang for the length
      # of a multi-GB upload. systemd-run hands the push to a transient unit and
      # returns immediately; --collect reaps it when it exits.
      #
      # cachix push walks the closure of $OUT_PATHS but skips paths already
      # available on cache.nixos.org, so upstream nixpkgs is never duplicated
      # into our cache. Verified against gen 68: of 3484 closure paths, the 356
      # absent from cache.nixos.org were exactly the 356 present in our cache.
      #
      # Token file holds CACHIX_AUTH_TOKEN=<token>. Leading "-" so the push unit
      # still starts if agenix hasn't decrypted it yet (that push just fails).
      nix.settings.post-build-hook = pkgs.writeShellScript "cachix-push" ''
        set -eu
        exec ${pkgs.systemd}/bin/systemd-run \
          --no-block --collect \
          --setenv=HOME=/root \
          --property=EnvironmentFile=-${config.age.secrets.cachix-token.path} \
          ${pkgs.cachix}/bin/cachix push ${cache} $OUT_PATHS
      '';
    };
}
