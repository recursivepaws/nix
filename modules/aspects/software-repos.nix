{ den, ... }:
{
  den.aspects.software-repos = {
    homeManager =
      {
        pkgs,
        config,
        lib,
        user,
        ...
      }:
      let
        isWork = user.userName == "work";
        isVera = user.userName == "vera";

        # GitHub owner to repo names, cloned as git@github.com:owner/repo.git into ~/Software/repo.
        repos = {
          recursivepaws = [
            "skills"
            "devshells"
            "nirukta"
            "nirukta-inflect"
          ]
          ++ lib.optionals isWork [ "documentation" ]
          ++ lib.optionals isVera [ "polyblade" ];

          hightouchio = lib.optionals isWork [
            "docs"
            "hightouch"
            "hightouch-ui"
            "infra"
          ];
        };

        software = "${config.home.homeDirectory}/Software";
        ssh = "${pkgs.openssh}/bin/ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new";

        cloneOne = owner: name: ''
          if [ ! -e ${lib.escapeShellArg "${software}/${name}"} ]; then
            run ${pkgs.git}/bin/git -c core.sshCommand=${lib.escapeShellArg ssh} \
              clone --recurse-submodules ${lib.escapeShellArg "git@github.com:${owner}/${name}.git"} \
              ${lib.escapeShellArg "${software}/${name}"} \
              || warnEcho ${lib.escapeShellArg "software-repos: skipped ${name} (clone failed, ssh key missing?)"}
          fi
        '';

        cloneAll = lib.flatten (lib.mapAttrsToList (owner: names: map (cloneOne owner) names) repos);
      in
      {
        # Bootstrap only: existing directories are never touched, so working copies stay untouched.
        # Clones fail soft with a warning so a fresh machine without ssh keys still activates.
        home.activation.cloneSoftwareRepos = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          mkdir -p ${lib.escapeShellArg software}
          ${lib.concatStringsSep "\n" cloneAll}
        '';
      };
  };
}
