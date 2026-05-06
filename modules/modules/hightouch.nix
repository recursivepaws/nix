{ den, ... }:
{
  den.aspects.hightouch = {

    # provides.to-hosts.nixos =
    #   { pkgs, ... }:
    #   {
    #     users.groups.docker = { };
    #   };
    #
    # includes = [
    #   den.provides.to-users =
    # ];

    nixos =
      {
        pkgs,
        config,
        user,
        ...
      }:
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

        security.pki.certificateFiles = [
          (pkgs.fetchurl {
            url = "https://ht-dev-agents-assets.s3.us-west-2.amazonaws.com/hightouch-development-root.cer";
            hash = "sha256-yRYHTdTico/Zd1uwAho4CG+TnmeEyJ2vJEEGAf7bxVQ=";
          })
        ];

        # systemd.services.write-npmrc = {
        #   description = "Establish Authorized NPM Connection";
        #   wantedBy = [ "multi-user.target" ];
        #   after = [ "run-agenix.d.mount" ];
        #   # requires = [ "run-agenix.d.mount" ];
        #   serviceConfig = {
        #     Type = "oneshot";
        #     User = user.userName;
        #     ExecStart = pkgs.writeShellScript "write-npmrc" ''
        #       source /run/agenix/secrets
        #       echo "meow meow!"
        #     '';
        #   };
        #
        # };

        # systemd.timers.write-npmrc = {
        #   wantedBy = [ "timers.target" ];
        #   timerConfig = {
        #     OnBootSec = "2min";
        #     OnCalendar = "daily";
        #   };
        # };
      };

    homeManager =
      {
        pkgs,
        config,
        lib,
        ...
      }:
      let
        # The specific version of node pinned in `pnpm-workspace.yaml`
        nodejs =
          let
            version = "20.19.2";
          in
          pkgs.nodejs_20.overrideAttrs (old: {
            version = version;
            src = pkgs.fetchurl {
              url = "https://nodejs.org/dist/v${version}/node-v${version}.tar.xz";
              sha256 = "sha256-Sn/2EdUYD05CAgT6byL5+d6yrF6YYZ3ZpN6H7fWwO24=";
            };
          });
      in
      {
        home =
          let
            deps = with pkgs; [
              curl
              wget
              getconf
            ];
            depPaths = (builtins.concatStringsSep ":" (map (dep: "${dep}/bin") deps));
          in
          {
            # activation = {
            #   hightouchSetup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            #     export PATH="${depPaths}:$PATH"
            #     export PNPM_HOME="${config.home.homeDirectory}/.local/share/pnpm"
            #     export ENV_FILE="/dev/null"
            #     export PROJECT_PATH="${config.home.homeDirectory}/Software/hightouch";
            #     if [[ ! -d "$PROJECT_PATH" ]]; then
            #       mkdir -p "$PROJECT_PATH"
            #     fi
            #     cd "$PROJECT_PATH"
            #
            #     # Install pnpm
            #     curl -fsSL https://get.pnpm.io/install.sh | sh -
            #
            #     # Set the nodeVersion based on the workspace yaml
            #     # pnpm env use --global $(grep "nodeVersion" pnpm-workspace.yaml | sed 's/.*nodeVersion: *\([0-9.]*\).*/\1/')
            #   '';
            # };

            sessionVariables = {
              JAVA_HOME = "${pkgs.openjdk}";
              CPPFLAGS = "-I${pkgs.openjdk}/include";
            };

            packages =
              with pkgs;
              [
                nodejs
                pnpm

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
              ]
              ++ deps;

            # file.".npmrc".source = config.age.secrets.npmrc.path;
          };

      };
  };
}
