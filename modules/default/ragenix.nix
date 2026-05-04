{ inputs, ... }: {
  flake-file.inputs.agenix = {
    url = "github:ryantm/agenix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.default.nixos = { pkgs, ... }: {
    # imports = [ inputs.agenix.nixosModules.default ];
    # environment.systemPackages = with pkgs; [ ragenix ];
    # age.identityPaths =
    #   [ "/etc/ssh/ssh_host_ed25519_key" "/home/vera/.ssh/id_ed25519" ];
    # age.secrets = {
    #   startup = {
    #     file = ../../secrets/startup.age;
    #     owner = "root";
    #     group = "root";
    #   };
    # };
  };
}

