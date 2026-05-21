{
  den.default.nixos =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        (pkgs.writeShellScriptBin "rebuild" ''
          set -euo pipefail

          HOST=$(hostname)
          HM_SERVICE="home-manager-$(whoami).service"
          NIXOS_DIR="/etc/nixos"
          MAX_RETRIES=5
          attempt=0

          while true; do
            if [ "$attempt" -ge "$MAX_RETRIES" ]; then
              echo "rebuild: gave up after $MAX_RETRIES attempts" >&2
              exit 1
            fi

            start_time=$(date -Is)
            attempt=$((attempt + 1))

            if (cd "$NIXOS_DIR" && nix run ".#''${HOST}" -- switch "$@"); then
              exit 0
            fi

            conflicts=$(
              journalctl -u "$HM_SERVICE" --since "$start_time" --no-pager 2>/dev/null \
                | ${pkgs.gnused}/bin/sed -n "s/.*Existing file '\(.*\)' would be clobbered.*/\1/p" \
                | sort -u
            )

            if [ -z "$conflicts" ]; then
              echo "rebuild: build failed (not a clobber conflict)" >&2
              exit 1
            fi

            echo ""
            echo "home-manager would clobber:"
            echo "$conflicts" | while IFS= read -r f; do echo "  $f"; done
            echo ""
            read -rp "[C]lobber / [B]ackup / [A]bort? " -n 1 choice </dev/tty
            echo ""

            case "''${choice,,}" in
              c)
                echo "$conflicts" | while IFS= read -r f; do
                  echo "  removing $f"
                  rm -f "$f"
                done
                ;;
              b)
                ts=$(date +%Y%m%d-%H%M%S)
                echo "$conflicts" | while IFS= read -r f; do
                  echo "  backing up $f -> ''${f}.''${ts}.bak"
                  mv "$f" "''${f}.''${ts}.bak"
                done
                ;;
              *)
                echo "Aborted." >&2
                exit 1
                ;;
            esac
          done
        '')
      ];
    };
}
