{
  den.aspects.hightouch = {

    # provides.to-hosts.nixos =
    #   { pkgs, ... }:
    #   {
    #     users.groups.docker = { };
    #   };
    #
    # provides.to-users =
    #   { user, ... }:
    #   {
    #     nixos.users.users.${user.name}.extraGroups = [ "docker" ];
    #   };

    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [
          # Core CLI tools
          git
          jq
          caddy
          unixodbc

          # Runtimes & languages
          go
          openjdk
          python3

          # Database
          postgresql_15
        ];

        # Required by tilt
        virtualisation.docker.enable = true;
      };

    homeManager =
      { pkgs, ... }:
      {
        home.sessionVariables = {
          JAVA_HOME = "${pkgs.openjdk}";
          CPPFLAGS = "-I${pkgs.openjdk}/include";
        };

        home.packages = with pkgs; [
          # Dev workflow
          git-spice # Stacked PRs
          tilt # Local dev orchestration (Docker Compose)
          _1password-cli # Secrets management
          autossh
          fzf

          # Python tooling
          pipx
          python312Packages.setuptools # python-setuptools
          # libomp # OpenMP for LightGBM
        ];
      };
  };
}
