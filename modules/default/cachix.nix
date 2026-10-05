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

      # Push every locally-built path. Runs only after a real build, so
      # paths already fetched from a substituter are never re-uploaded.
      nix.settings.post-build-hook = pkgs.writeShellScript "cachix-push" ''
        set -eu
        export HOME=/root
        ${pkgs.cachix}/bin/cachix push ${cache} $OUT_PATHS \
          || echo "cachix push failed, continuing" >&2
      '';

      # File holds CACHIX_AUTH_TOKEN=<token>. Leading "-" so nix-daemon still
      # starts if agenix hasn't decrypted it yet (pushes just fail that boot).
      systemd.services.nix-daemon.serviceConfig.EnvironmentFile =
        "-${config.age.secrets.cachix-token.path}";
    };
}
