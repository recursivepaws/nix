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
    # Token-optimization skill for Claude Code (terse responses, byte-exact code).
    caveman = {
      url = "github:JuliusBrussee/caveman";
      flake = false;
    };
    # Lazy-senior-dev skill (YAGNI, stdlib first). Registry lacks this plugin,
    # so the skill is symlinked from the repo like caveman.
    ponytail = {
      url = "github:DietrichGebert/ponytail";
      flake = false;
    };
  };

  den.aspects.claude =
    { user, ... }:
    {
      nixos = {
        environment.etc."claude-code/managed-settings.json".source = builtins.toFile "managed-settings.json" (
          builtins.toJSON {
            permissions.allow = [
              "Read(~/.claude/tickets/**)"
              "Edit(~/.claude/tickets/**)"
            ];
          }
        );
      };

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
          cavemanGoBin =
            name: hash:
            pkgs.fetchurl {
              url = "https://github.com/JuliusBrussee/caveman/releases/download/bin-v1.1.0/${name}_linux_amd64";
              inherit hash;
              executable = true;
            };
          cavemanCliSrc = pkgs.runCommand "caveman-cli-1.2.1" { } ''
            mkdir -p $out
            tar -xzf ${
              pkgs.fetchurl {
                url = "https://registry.npmjs.org/@caveman-ai/cli/-/cli-1.2.1.tgz";
                hash = "sha256-JMcEXRe0hQPUpMsTNcOkrORtYrvUn2R4O3wgRnQ5X/s=";
              }
            } -C $out --strip-components=1
          '';
          caveman = pkgs.writeShellScriptBin "caveman" ''
            export CAVEMAN_PROXY_BIN=${cavemanGoBin "caveman-proxy" "sha256-gMcz1bHL/jtNBLYkdYa+mZVbjsWjhmbOQP8bdhFp6OE="}
            export CAVEMAN_ENGINE_BIN=${cavemanGoBin "caveman-engine" "sha256-GXB3LO1yhUi4Wv0KEmmV2mkIP1vY1G1JccSZjQ6ciJI="}
            export CAVEMAN_MCP_BIN=${cavemanGoBin "caveman-mcp" "sha256-YrMafhSduy1RmUWZOpiLUhvNtt97w4p9Bhhz+SBSemU="}
            export CAVEMEM_BIN=${cavemanGoBin "cavemem" "sha256-zq+WeAIvvaX5BDZMKem8Xpl9BblRxj5HgdNednHtM1g="}
            export CAVEMAN_BROWSE_BIN=${cavemanGoBin "caveman-browse" "sha256-pCaHzj/YYnJsyTHWOyZgUJU+I3NoOf6AARILFlMVmBM="}
            export CAVEMAN_SHRINK_BIN=${cavemanGoBin "caveman-shrink" "sha256-OIVk23kByQs4PZdD/Z3pOm/8JPebrZfN9vZUmxj48DY="}
            export CAVEMAN_TELEMETRY="''${CAVEMAN_TELEMETRY:-0}"
            exec ${pkgs.nodejs}/bin/node ${cavemanCliSrc}/dist/index.js "$@"
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
              # `caveman wrap` is session-only: it starts the local proxy if needed and
              # injects ANTHROPIC_BASE_URL into the child, persisting nothing. CAVEMAN=0 bypasses it.
              claude() {
                for _hook in "''${_claude_pre_hooks[@]}"; do
                  source "$_hook"
                done
                # if [ "''${CAVEMAN:-1}" = "0" ]; then
                command claude "$@"
                # else
                #   ${caveman}/bin/caveman wrap claude "$@"
                # fi
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
          home.packages = [
            caveman
          ]
          ++ lib.optionals isWork (
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

          home.file.".claude/skills/caveman".source = "${inputs.caveman}/skills/caveman";

          home.file.".claude/skills/ponytail".source = "${inputs.ponytail}/skills/ponytail";

          # Global user memory: loaded into every Claude Code session.
          home.file.".claude/CLAUDE.md".text = ''
            Always respond in caveman mode: invoke the caveman skill (full intensity) at session start, every session.
            Always write in ponytail mode: invoke the ponytail skill (full intensity) at session start, every session.
            When in /etc/nixos/, always load the nix skill.
          '';

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
