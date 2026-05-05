{ inputs, ... }:
{
  flake-file.inputs.agenix = {
    url = "github:ryantm/agenix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # den.default.homeManager =
  #   { pkgs, ... }:
  #   {
  #     home.sessionPath = with pkgs; [ "${age-plugin-yubikey}/bin" ];
  #   };
  den.default.nixos =
    { pkgs, ... }:
    let
      ageBin = pkgs.writeShellScript "age-with-plugins" ''
        export PATH="${pkgs.age-plugin-yubikey}/bin:$PATH"
        exec ${pkgs.rage}/bin/rage "$@"
      '';
    in
    {
      imports = [ inputs.agenix.nixosModules.default ];

      environment.systemPackages = with pkgs; [
        rage
        ragenix
        age-plugin-yubikey
      ];

      services.pcscd.enable = true;

      age.ageBin = "${ageBin}";
      age.identityPaths = [
        "/etc/ssh/ssh_host_ed25519_key"
        ../../assets/age-yubikey-identity-8f6fdf41.txt
      ];

      age.secrets = {
        startup = {
          file = ../../secrets/startup.age;
          owner = "root";
          group = "secrets";
          mode = "0440";
        };
      };
    };
}
