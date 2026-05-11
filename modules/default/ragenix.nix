{ inputs, ... }:
{
  flake-file.inputs.agenix = {
    url = "github:ryantm/agenix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.default.nixos =
    { pkgs, ... }:
    let
      plugins = with pkgs; [
        age-plugin-yubikey
        age-plugin-1p
      ];
      pluginPaths = (builtins.concatStringsSep ":" (map (plugin: "${plugin}/bin") plugins));
      ageBin = pkgs.writeShellScript "age-with-plugins" ''
        export PATH="${pluginPaths}:$PATH"
        exec ${pkgs.rage}/bin/rage "$@"
      '';
    in
    {
      imports = [ inputs.agenix.nixosModules.default ];

      environment.systemPackages =
        with pkgs;
        [
          rage
          ragenix
        ]
        ++ plugins;

      services.pcscd.enable = true;

      age.ageBin = "${ageBin}";
      age.identityPaths = [
        "/etc/ssh/ssh_host_ed25519_key"
        ../../assets/age-yubikey-identity.txt
        ../../assets/age-1p-identity.txt
      ];

      age.secrets = {
        secrets = {
          file = ../../secrets/secrets.age;
          owner = "root";
          group = "secrets";
          mode = "0440";
        };
        "github.token" = {
          file = ../../secrets/github.token.age;
          owner = "root";
          group = "secrets";
          mode = "0440";
        };
      };
    };
}
