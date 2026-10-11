{ inputs, ... }:
{
  den.aspects.hightouch = {
    homeManager =
      { pkgs, config, ... }:
      let
        # Same node/pnpm pin as hightouch.nix — the version in pnpm-workspace.yaml.
        nodePkgs = inputs.nixpkgs-node.legacyPackages.${pkgs.stdenv.hostPlatform.system};
        nodejs = nodePkgs.nodejs_24;
        pnpm = nodePkgs.pnpm.override { nodejs-slim = nodePkgs.nodejs-slim_24; };

        # Create (or repair) a per-ticket worktree of the Hightouch monorepo.
        #
        # One ticket = one worktree = one branch. $HIGHTOUCH_ROOT stays on master
        # and exists to run Tilt; ticket work never happens there. Worktrees are
        # flat siblings of the root, named after the ticket: ~/Software/plat-1234.
        #
        # .envrc, node_modules and the .env* secrets are all gitignored, so a fresh
        # worktree has none of them and a missing one fails later in a way that
        # looks like a code bug. Hence all five steps, and hence re-running on an
        # existing worktree re-hydrates rather than erroring — this doubles as the
        # "fix my worktree" command.
        htWorktree = pkgs.writeShellApplication {
          name = "ht-worktree";
          runtimeInputs = [
            nodejs
            pnpm
          ]
          ++ (with pkgs; [
            git
            direnv
            bash
            gnugrep
            coreutils
          ]);
          text = ''
            root="''${HIGHTOUCH_ROOT:-${config.home.homeDirectory}/Software/hightouch}"
            [ -d "$root/.git" ] || { echo "ht-worktree: $root is not the main checkout" >&2; exit 1; }

            branch="''${1:?usage: ht-worktree <branch> [dirname]}"
            base="''${branch##*/}"
            name="''${2:-$(printf '%s' "$base" | grep -oiE '^[a-z]+-[0-9]+' || printf '%s' "$base")}"
            dir="$(dirname "$root")/$name"

            # The root owns Tilt/compose here. Warn rather than block: it may
            # legitimately sit on a release branch for a moment.
            head="$(git -C "$root" symbolic-ref --quiet --short HEAD || echo '(detached)')"
            [ "$head" = master ] || \
              echo "warning: $root is on '$head', not master; it owns Tilt/compose on this machine." >&2

            if [ -d "$dir" ]; then
              echo "ht-worktree: $dir exists — re-hydrating"
            else
              git -C "$root" fetch --quiet origin
              if git -C "$root" rev-parse --verify --quiet "refs/heads/$branch" >/dev/null; then
                git -C "$root" worktree add "$dir" "$branch"
              elif git -C "$root" rev-parse --verify --quiet "refs/remotes/origin/$branch" >/dev/null; then
                git -C "$root" worktree add --track -b "$branch" "$dir" "origin/$branch"
              else
                git -C "$root" worktree add -b "$branch" "$dir" origin/master
              fi
            fi

            # .envrc is per-worktree; .git/info/exclude is shared across worktrees,
            # so the ignore entry is already in place.
            [ -e "$dir/.envrc" ] || \
              printf 'use flake %s/Software/devshells#hightouch\n' "${config.home.homeDirectory}" > "$dir/.envrc"
            direnv allow "$dir" || \
              echo "ht-worktree: direnv allow failed (is ~/Software/devshells cloned?)" >&2

            (cd "$dir" && pnpm install)

            # Reuse the repo's own secrets copier. It resolves its destination with
            # `git rev-parse --show-toplevel`, so run it with cwd inside the worktree.
            if [ -f "$root/.cursor/copy-worktree-secrets.sh" ]; then
              (cd "$dir" && ROOT_WORKTREE_PATH="$root" bash "$root/.cursor/copy-worktree-secrets.sh")
            else
              # Fallback: decrypt in place. Use the dotenvx that pnpm install just
              # put in node_modules (1.14.1, matching the repo's mise.toml pin)
              # rather than anything on the ambient PATH — bin/secrets resolves it
              # by `shutil.which`, and a major version mismatch against committed
              # ciphertext is not worth risking.
              (cd "$dir" \
                && PATH="$dir/packages/backend/core/node_modules/.bin:$PATH" \
                   ./bin/secrets inject)
            fi

            echo
            echo "ready: $dir"
            echo "  cd $dir && pnpm tilt:local worker     # Tilt infers --dir from cwd"
            echo "  (never run 'start' / 'tilt:start' here — Tilt-root only: $root)"
          '';
        };
      in
      {
        home.packages = [ htWorktree ];
      };
  };
}
