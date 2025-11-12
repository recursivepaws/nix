{ lib, pkgs, ... }: {
  programs = {
    ssh = let opAgent = "~/.1password/agent.sock";
    in {
      enable = true;
      # enableDefaultConfig = false;
      extraConfig = ''
        Host *
          IdentityAgent ${opAgent}
      '';
    };
    git = {
      enable = true;
      settings = {
        gpg = { format = "ssh"; };
        "gpg \"ssh\"" = {
          program = "${lib.getExe' pkgs._1password-gui "op-ssh-sign"}";
        };
        commit = { gpgsign = true; };
        user = {
          email = "me@vera.lgbt";
          name = "Vera Gonzalez";
          signingKey =
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIINY5xZYRlbxjdw4N47VADFRSU3EeSI3Yze97F8cWGLS";
        };
      };

    };
  };
}
