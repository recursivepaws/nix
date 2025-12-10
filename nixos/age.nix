{ config, ... }:
let
  # Get the primary user from NixOS config
  mainUser = config.users.users.vera;
in {
  age.identityPaths =
    [ "/etc/ssh/ssh_host_ed25519_key" "${mainUser.home}/.ssh/id_ed25519" ];

  age.secrets = {
    startup = {
      file = ../secrets/startup.age;
      owner = "root";
      group = "root";
    };
    # network = {
    #   file = ../secrets/network.age;
    # };
  };
}
