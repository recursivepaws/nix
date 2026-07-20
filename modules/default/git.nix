{
  den.default.homeManager =
    { lib, pkgs, ... }:
    {
      programs = {
        ssh =
          let
            opAgent = "~/.1password/agent.sock";
          in
          {
            enable = true;
            enableDefaultConfig = false;
            matchBlocks = {
              "*".extraOptions.IdentityAgent = opAgent;
              "github.com".extraOptions = {
                IdentityFile = "~/.ssh/id_github.pub";
                IdentitiesOnly = "yes";
              };
            };
          };

        git = {
          enable = true;
          ignores = [
            ".direnv/"
            "**/.claude/settings.local.json"
          ];
          settings = {
            gpg = {
              format = "ssh";
            };
            "gpg \"ssh\"" = {
              program = "${lib.getExe' pkgs._1password-gui "op-ssh-sign"}";
            };
            commit = {
              gpgsign = true;
            };
            user = {
              email = "me@vera.lgbt";
              name = "Vera Gonzalez";
              signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIINY5xZYRlbxjdw4N47VADFRSU3EeSI3Yze97F8cWGLS";
            };
          };
          settings.alias = {
            default-branch = "config init.defaultBranch";
            current-branch = "rev-parse --abbrev-ref HEAD";
            upstream-branch = ''!git for-each-ref --format='%(upstream:short)' "$(git symbolic-ref -q HEAD)"'';
            publish = ''!git push --set-upstream origin "$(git current-branch)"'';
            unpublish = ''!git push origin :"$(git current-branch)"'';
            stashes = "stash list";

            a = "add";
            b = "branch";
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

            ll = "log-list";
            lll = "log-list-long";
            lg = "log-graph";

            log-graph = "log --graph --all --oneline --decorate";
            log-list = "log --graph --topo-order --date=short --abbrev-commit --decorate --all --boundary --pretty=format:'%Cblue%ad %C(auto)%h%Creset -%C(auto)%d%Creset %s %Cblue[%aN]%Creset %Cblue%G?%Creset'";
            log-list-long = "log --graph --topo-order --date=iso8601-strict --no-abbrev-commit --decorate --all --boundary --pretty=format:'%Cblue%ad %C(auto)%h%Creset -%C(auto)%d%Creset %s %Cblue[%aN <%aE>]%Creset %Cblue%G?%Creset'";
            j = "pull";
            jr = "pull -r";
            k = "push";
            kf = "push -f";
            rb = "rebase";
            rbi = "rebase -i";
            # r = "remote";
            # ra = "remote add";
            # rr = "remote rm";
            # rv = "remote -v";
            # rs = "remote show";
            s = "status";
            r = "restore";
            rs = "restore --staged";
          };
        };

        zsh.initContent = ''
          gh() {
            if [ -f /run/agenix/github.token ]; then
              GH_TOKEN=$(cat /run/agenix/github.token) command gh "$@"
            else
              echo "warning: /run/agenix/github.token not found, gh may not be authenticated" >&2
              command gh "$@"
            fi
          }
          source ${pkgs.fzf-git-sh}/share/fzf-git-sh/fzf-git.sh
        '';
      };

      home.file.".ssh/id_github.pub".text = ''
        ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIINY5xZYRlbxjdw4N47VADFRSU3EeSI3Yze97F8cWGLS vera-github
      '';

      home.packages = with pkgs; [
        fzf
        fzf-git-sh
        gh
      ];
    };
}
