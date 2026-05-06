{
  den.aspects.hightouch = {
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
      };

    homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          # Dev workflow
          git-spice # Stacked PRs
          tilt # Local dev orchestration (Docker Compose)
          _1password-cli # Secrets management

          # Python tooling
          pipx
          python312Packages.setuptools # python-setuptools
          # libomp # OpenMP for LightGBM
        ];
      };
  };
}
