{ inputs, ... }:
{
  flake-file.inputs = {
    claude-plugins-nix.url = "github:mreimbold/claude-plugins-nix";
    mcp-servers-nix = {
      url = "github:natsukium/mcp-servers-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Claude skills live in their own (private) repo; consumed as a plain source tree.
    skills = {
      url = "git+ssh://git@github.com/recursivepaws/skills";
      flake = false;
    };
  };

  den.aspects.claude =
    { user, ... }:
    {
      homeManager =
        {
          pkgs,
          lib,
          config,
          ...
        }:
        let
          claudePluginsPkg =
            inputs.claude-plugins-nix.packages.${pkgs.stdenv.hostPlatform.system}.claude-plugins;
          isWork = user.userName == "work";
          plugins = [
            "@anthropics/claude-code-plugins/pr-review-toolkit"
            "@anthropics/claude-code-plugins/commit-commands"
            "@anthropics/claude-code-plugins/code-review"
            "@anthropics/claude-plugins-official/code-simplifier"
            "@anthropics/claude-plugins-official/skill-creator"
            "@anthropics/claude-plugins-official/lua-lsp"
            "@anthropics/claude-plugins-official/rust-analyzer-lsp"
          ]
          ++ lib.optionals isWork [
            "@anthropics/claude-plugins-official/linear"
            "@anthropics/claude-plugins-official/typescript-lsp"
          ]
          ++ lib.optionals (!isWork) [ ];
          # Run npx from $HOME so project configs can't interfere.
          npxFromHome = pkgs.writeShellScript "npx-from-home" ''
            cd "$HOME"
            exec ${pkgs.nodejs}/bin/npx "$@"
          '';
        in
        {
          imports = with inputs; [
            claude-plugins-nix.homeManagerModules.default
            mcp-servers-nix.homeManagerModules.default
          ];

          programs.zsh.initContent =
            let
              agenixHook = pkgs.writeShellScript "claude-hook-agenix" ''
                if [ -f /run/agenix/agent-env ]; then
                  source /run/agenix/agent-env
                  echo "info: sourced agenix agent-env"
                else
                  echo "warning: /run/agenix/agent-env not found, agent environment variables may be missing" >&2
                fi
              '';
            in
            lib.mkOrder 900 ''
              _claude_pre_hooks=(${agenixHook})
              claude() {
                for _hook in "''${_claude_pre_hooks[@]}"; do
                  source "$_hook"
                done
                command claude "$@"
              }
            '';

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
                package = inputs.claude-plugins-nix.packages.${pkgs.stdenv.hostPlatform.system}.skills-installer;
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
            };
          };

          mcp-servers.settings.servers =
            { }
            // lib.optionalAttrs isWork {
              circleci = {
                command = "${npxFromHome}";
                args = [
                  "-y"
                  "@circleci/mcp-server-circleci@latest"
                ];
                env = {
                  CIRCLECI_TOKEN = "\${CIRCLECI_TOKEN}";
                };
              };
              snowflake = {
                url = "\${SNOWFLAKE_MCP_URL}";
                headers = {
                  Authorization = "Bearer \${SNOWFLAKE_PAT}";
                };
              };
              datadog = {
                command = "${npxFromHome}";
                args = [
                  "-y"
                  "@winor30/mcp-server-datadog"
                ];
                env = {
                  DATADOG_API_KEY = "\${DATADOG_API_KEY}";
                  DATADOG_APP_KEY = "\${DATADOG_APP_KEY}";
                };
              };
              slack = {
                command = "${npxFromHome}";
                args = [
                  "-y"
                  "slack-mcp-server@latest"
                  "--transport"
                  "stdio"
                ];
                env = {
                  SLACK_MCP_XOXC_TOKEN = "\${SLACK_MCP_XOXC_TOKEN}";
                  SLACK_MCP_XOXD_TOKEN = "\${SLACK_MCP_XOXD_TOKEN}";
                };
              };
              hightouch-internal = {
                command = "${npxFromHome}";
                args = [
                  "-y"
                  "@hightouchio/internal-mcp@latest"
                ];
                env = {
                  HIGHTOUCH_API_KEY = "\${HIGHTOUCH_API_KEY}";
                };
              };
            }
            // lib.optionalAttrs (!isWork) {
              # TODO: vera-only servers here
            };

          # These are required for the `typescript-lsp` plugin
          home.packages = lib.optionals isWork (
            with pkgs;
            [
              typescript-language-server
              typescript
            ]
          );

          # Symlink every skill from the recursivepaws/skills flake input into ~/.claude/skills.
          # recursive = true links files individually, so installer-managed skills (e.g. pdf)
          # still coexist here. Adding/editing a skill = push to that repo, then
          # `nix flake update skills` and rebuild — no change needed in this file.
          home.file.".claude/skills" = lib.mkIf isWork {
            source = inputs.skills;
            recursive = true;
          };

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
