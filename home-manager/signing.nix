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
      aliases = {
        a = "add";
        aa = "add -A";
        c = "commit";
        ca = "commit --amend";
        can = "commit --amend --no-edit";
        cl = "clone";
        cm = "commit -m";
        co = "checkout";
        cp = "cherry-pick";
        cpx = "cherry-pick -x";
        d = "diff";
        f = "fetch";
        fo = "fetch origin";
        fu = "fetch upstream";
        lol = "log --graph --decorate --pretty=oneline --abbrev-commit";
        lola = "log --graph --decorate --pretty=oneline --abbrev-commit --all";
        j = "pull";
        jr = "pull -r";
        k = "push";
        kf = "push -f";
        rb = "rebase";
        rbi = "rebase -i";
        r = "remote";
        ra = "remote add";
        rr = "remote rm";
        rv = "remote -v";
        rs = "remote show";
        s = "status";
      };
    };
  };
}
