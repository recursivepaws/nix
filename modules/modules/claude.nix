{ inputs, ... }:
{
  flake-file.inputs = {
    claude-plugins-nix.url = "github:mreimbold/claude-plugins-nix";
    mcp-servers-nix = {
      url = "github:natsukium/mcp-servers-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  den.aspects.claude = {
    homeManager =
      {
        pkgs,
        lib,
        config,
        ...
      }:
      let
        claudePluginsPkg = inputs.claude-plugins-nix.packages.${pkgs.system}.claude-plugins;
        plugins = [
          "@anthropics/claude-code-plugins/pr-review-toolkit"
          "@anthropics/claude-code-plugins/commit-commands"
          "@anthropics/claude-code-plugins/code-review"
          "@anthropics/claude-plugins-official/typescript-lsp"
          # "@anthropics/claude-plugins-official/rust-analyzer-lsp"
          "@anthropics/claude-plugins-official/linear"
          "@anthropics/claude-plugins-official/code-simplifier"
          "@anthropics/claude-plugins-official/skill-creator"
        ];
      in
      {
        imports = with inputs; [
          claude-plugins-nix.homeManagerModules.default
          mcp-servers-nix.homeManagerModules.default
        ];

        programs = {
          claude-tools = {
            # Enable plugin manager
            claude-plugins = {
              enable = true;
              package = claudePluginsPkg;
              inherit plugins;
            };

            # Enable skills installer
            skills-installer = {
              enable = true;
              package = inputs.claude-plugins-nix.packages.${pkgs.system}.skills-installer;
              clients = [
                "claude-code"
                # "cursor"
              ];
              globalSkills = [
                # "@anthropics/skills/frontend-design"
                "@anthropics/skills/pdf"
              ];
            };
          };

          mcp.enable = true;
          claude-code = {
            enable = true;
            enableMcpIntegration = true;
          };
        };

        mcp-servers.programs = {
          fetch.enable = true;
          context7.enable = true;
          memory.enable = true;
          sequential-thinking.enable = true;
          nixos.enable = true;
          filesystem = {
            enable = true;
            args = [ "${config.home.homeDirectory}/Software" ];
          };
          git.enable = true;
          github = {
            enable = true;
            env = {
              GITHUB_PERSONAL_ACCESS_TOKEN = "\${GITHUB_PERSONAL_ACCESS_TOKEN}";
            };
            # passwordCommand = {
            #   GITHUB_PERSONAL_ACCESS_TOKEN = [
            #     "cat"
            #     "/run/agenix/github.token"
            #   ];
            # };
          };
        };

        mcp-servers.settings.servers.snowflake = {
          url = "\${SNOWFLAKE_MCP_URL}";
          headers = {
            Authorization = "Bearer \${SNOWFLAKE_PAT}";
          };
        };

        mcp-servers.settings.servers.circleci = {
          command = "${pkgs.nodejs}/bin/npx";
          args = [
            "-y"
            "@circleci/mcp-server-circleci@latest"
          ];
          env = {
            CIRCLECI_TOKEN = "\${CIRCLECI_TOKEN}";
          };
        };

        mcp-servers.settings.servers.datadog = {
          command = "${pkgs.nodejs}/bin/npx";
          args = [
            "-y"
            "@winor30/mcp-server-datadog"
          ];
          env = {
            DATADOG_API_KEY = "\${DATADOG_API_KEY}";
            DATADOG_APP_KEY = "\${DATADOG_APP_KEY}";
          };
        };

        home.file.".claude/skills/destination/SKILL.md".text = builtins.readFile ./destination-skill.md;

        # Upstream module doesn't add git to PATH during activation, so clone fails.
        # Override the activation script to fix this (pending upstream PR).
        home.activation.installClaudePlugins = lib.mkForce (
          lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            export PATH="${pkgs.git}/bin:$PATH"
            $DRY_RUN_CMD ${claudePluginsPkg}/bin/claude-plugins list > /dev/null 2>&1 || true
            ${lib.concatMapStringsSep "\n" (plugin: ''
              if ! ${claudePluginsPkg}/bin/claude-plugins list 2>/dev/null | grep -q "${plugin}"; then
                $VERBOSE_ECHO "Installing plugin: ${plugin}"
                $DRY_RUN_CMD ${claudePluginsPkg}/bin/claude-plugins install "${plugin}" || true
              fi
            '') plugins}
          ''
        );
      };
  };
}
