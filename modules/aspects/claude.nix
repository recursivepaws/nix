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
    # Python dev skills (project setup, code quality, testing, security audit).
    python-skills = {
      url = "github:wdm0006/python-skills";
      flake = false;
    };
    # NixOS management skill: rebuild/flake/module best practices, anti-patterns.
    nixos-management-skill = {
      url = "github:michalzubkowicz/nixos-management-skill";
      flake = false;
    };
    # Rust best-practices skill from Apollo's skills collection.
    apollo-skills = {
      url = "github:apollographql/skills";
      flake = false;
    };
    humanizer = {
      url = "github:blader/humanizer";
      flake = false;
    };
    # Reverse-engineer web APIs from HAR captures into Python clients.
    # Pinned: skill was removed from the repo's main branch after this commit.
    reverse-api-engineer = {
      url = "github:kalil0321/reverse-api-engineer/0f37681741faf2670310048c92a00d5bfb1de822";
      flake = false;
    };
    # Unsplash photo search MCP server (plain server.py, deps from nixpkgs).
    unsplash-mcp = {
      url = "github:cevatkerim/unsplash-mcp";
      flake = false;
    };
    # DaVinci Resolve MCP server (plain server.py against Resolve's scripting API).
    davinci-resolve-mcp = {
      url = "github:samuelgursky/davinci-resolve-mcp";
      flake = false;
    };
  };

  den.aspects.claude =
    { user, ... }:
    {
      nixos = {
        environment.etc."claude-code/managed-settings.json".source =
          builtins.toFile "managed-settings.json"
            (
              builtins.toJSON {
                permissions.allow = [
                  "Read(//home/*/Software/tickets/**)"
                  "Edit(//home/*/Software/tickets/**)"
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
          isVera = user.userName == "vera";
          plugins = [
            "@anthropics/claude-code-plugins/pr-review-toolkit"
            "@anthropics/claude-code-plugins/frontend-design"
            # Design skills: impeccable.style, designwithintent.ai, ui-ux-pro-max
            "@pbakaus/impeccable/impeccable"
            "@ghaida/intent/intent"
            "@nextlevelbuilder/ui-ux-pro-max-skill/ui-ux-pro-max"
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
          ];
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
          resolveMcpPython = pkgs.python3.withPackages (ps: [ ps.mcp ]);
          unsplashPython = pkgs.python3.withPackages (
            ps: with ps; [
              fastmcp
              httpx
              python-dotenv
            ]
          );
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
          pdfPackages = with pkgs; [
            poppler-utils # pdfinfo, pdftotext, pdftoppm, pdfimages
            qpdf # merge/split/decrypt
            (python3.withPackages (
              ps: with ps; [
                pypdf
                pdfplumber
                reportlab
              ]
            ))
          ];
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
              # caveman-wrap auto-invocation is currently disabled; `claude` runs directly.
              # The `caveman` CLI is still installed for manual use: `caveman wrap claude`.
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
                ];
                globalSkills = [
                  "@anthropics/skills/pdf"
                ];
              };
            };

            mcp.enable = true;
            claude-code = {
              enable = true;
              enableMcpIntegration = true;
              # Nirukta LSP for .sutra/.sloka; server lives in the nirukta repo checkout.
              # Routed through that repo's #headless devshell: the venv's manylinux
              # wheels dlopen libstdc++/libGL at import time, so the server only
              # starts with the devshell's LD_LIBRARY_PATH. #headless rather than the
              # default shell because the latter's shellHook writes uv sync output and
              # an opengl.py traceback to stdout, corrupting the JSON-RPC stream.
              lspServers.nirukta = {
                command = "nix";
                args = [
                  "develop"
                  "path:${config.home.homeDirectory}/Software/nirukta#headless"
                  "-c"
                  "uv"
                  "run"
                  "--project"
                  "${config.home.homeDirectory}/Software/nirukta"
                  "nirukta-lsp"
                ];
                extensionToLanguage = {
                  ".sutra" = "nirukta";
                  ".sloka" = "nirukta";
                };
              };
            };
          };

          mcp-servers.programs = {
            fetch.enable = true;
            context7.enable = true;
            memory.enable = true;
            sequential-thinking.enable = true;
            nixos.enable = true;
            playwright.enable = true;
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
            lib.optionalAttrs isWork {
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
            // lib.optionalAttrs isVera {
              davinci-resolve = {
                command = "${resolveMcpPython}/bin/python";
                args = [ "${inputs.davinci-resolve-mcp}/src/server.py" ];
                env = {
                  RESOLVE_SCRIPT_API = "${pkgs.davinci-resolve-studio.davinci}/Developer/Scripting";
                  RESOLVE_SCRIPT_LIB = "${pkgs.davinci-resolve-studio.davinci}/libs/Fusion/fusionscript.so";
                };
              };
            }
            // {
              vercel = {
                url = "https://mcp.vercel.com";
              };
              sanity = {
                url = "https://mcp.sanity.io";
              };
              unsplash = {
                command = "${unsplashPython}/bin/python";
                args = [ "${inputs.unsplash-mcp}/server.py" ];
                env = {
                  UNSPLASH_ACCESS_KEY = "\${UNSPLASH_ACCESS_KEY}";
                };
              };
            };

          home.packages = [
            caveman
          ]
          ++ pdfPackages
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
          home.file = {
            ".claude/skills" = {
              source = inputs.skills;
              recursive = true;
            };

            ".claude/skills/humanizer".source = inputs.humanizer;

            # Global user memory: loaded into every Claude Code session.
            ".claude/CLAUDE.md".text = ''
              Always respond in caveman mode: invoke the caveman skill (full intensity) at session start, every session.
              Always write in ponytail mode: invoke the ponytail skill (full intensity) at session start, every session.
              When in /etc/nixos/, always load the nixos-managing skill.
            '';
          }
          # Skill name = last path segment.
          // lib.listToAttrs (
            map
              (
                source:
                lib.nameValuePair ".claude/skills/${baseNameOf (builtins.unsafeDiscardStringContext source)}" {
                  inherit source;
                }
              )
              [
                "${inputs.caveman}/skills/caveman"
                "${inputs.ponytail}/skills/ponytail"
                "${inputs.nixos-management-skill}/nixos-managing"
                "${inputs.apollo-skills}/skills/rust-best-practices"
                "${inputs.reverse-api-engineer}/plugins/reverse-api-engineer/skills/reverse-engineering-api"
                "${inputs.python-skills}/skills/python/project-setup"
                "${inputs.python-skills}/skills/python/code-quality"
                "${inputs.python-skills}/skills/python/testing-strategy"
                "${inputs.python-skills}/skills/python/security-audit"
              ]
          );

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
