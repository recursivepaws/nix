{ inputs, ... }:
{
  flake-file.inputs.direnv-instant.url = "github:Mic92/direnv-instant";

  den.default.homeManager =
    { pkgs, lib, ... }:
    {
      imports = [ inputs.direnv-instant.homeModules.direnv-instant ];

      programs = {
        direnv = {
          enable = true;
          enableZshIntegration = true;
          nix-direnv.enable = true;
        };
        direnv-instant = {
          enable = true;
          enableZshIntegration = true;
        };
        # TODO: learn more about `mkOrder` priorities
        zsh.initContent = lib.mkAfter ''
          eval "$(direnv hook zsh)"
        '';
      };
    };
}
