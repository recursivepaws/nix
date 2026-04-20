{
  den.aspects.yabridge = {
    homeManager = { pkgs, lib, ... }:
      let
        # Script to configure yabridge
        yabridgeSetup = pkgs.writeShellApplication {
          name = "yabridge-setup";
          runtimeInputs = with pkgs; [ gnugrep nix gnused yabridgectl ];
          text = ''
            # Get plugins from the current system's package closure
            # Use recursive query to find all dependencies, including plugins
            # This ensures we only use plugins from the active system configuration
            SYSTEM_REFS=$(nix-store -qR /run/current-system/sw 2>/dev/null || echo "")

            # Filter for plugin packages (exclude bundle and other non-VST packages)
            PLUGIN_PATHS=$(echo "$SYSTEM_REFS" | grep -E "(serum-|serum2-|shaperbox3-|vst-)" | grep -v "windows-plugin-bundle" | grep -v "vamp-plugin" | grep -v "thunar" || echo "")

            echo "Plugin Paths: $PLUGIN_PATHS"

            # Get current yabridge paths
            CURRENT_PATHS=$(yabridgectl list 2>/dev/null || echo "")

            # Remove all old nix store paths from yabridge
            # This prevents duplicates from accumulating
            for old_path in $CURRENT_PATHS; do
              if echo "$old_path" | grep -q "^/nix/store/"; then
                if ! echo "$PLUGIN_PATHS" | grep -q "^$old_path$"; then
                  echo "Removing old plugin path: $(basename "$old_path")"
                  yabridgectl rm "$old_path" 2>/dev/null || true
                fi
              fi
            done

            # Add current plugins
            if [ -n "$PLUGIN_PATHS" ]; then
              for plugin_path in $PLUGIN_PATHS; do
                # Check if this path contains VST files
                if [ -d "$plugin_path" ] && (find "$plugin_path" -name "*.vst3" -o -name "*.dll" 2>/dev/null | grep -q .); then
                  # Only add if not already in the list
                  if ! echo "$CURRENT_PATHS" | grep -q "^$plugin_path$"; then
                    PLUGIN_NAME=$(basename "$plugin_path" | sed 's/-[0-9].*//')
                    echo "Adding plugin: $PLUGIN_NAME"
                    ${pkgs.yabridgectl}/bin/yabridgectl add "$plugin_path"
                  fi
                fi
              done

              # Sync yabridge
              echo "Syncing yabridge..."
              yabridgectl sync
            else
              echo "No Windows plugins found in current system"
            fi
          '';
        };

      in {
        home = {
          # Run yabridge setup when home configuration is activated
          activation.yabridgeSetup =
            lib.hm.dag.entryAfter [ "writeBoundary" ] ''
              $DRY_RUN_CMD ${yabridgeSetup}/bin/yabridge-setup
            '';

          # Ensure yabridge directories exist
          file = {
            ".vst3/yabridge/.keep".text = "";
            ".vst/yabridge/.keep".text = "";
            ".clap/yabridge/.keep".text = "";
          };
        };
      };
  };
}
