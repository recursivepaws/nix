{
  flake.modules.homeManager.yabridge = { pkgs, lib, ... }:
    let

      # Script to configure yabridge
      yabridgeSetup = pkgs.writeShellScript "yabridge-setup" ''
        # Get plugins from the current system's package closure
        # Use recursive query to find all dependencies, including plugins
        # This ensures we only use plugins from the active system configuration
        SYSTEM_REFS=$(${pkgs.nix}/bin/nix-store -qR /run/current-system/sw 2>/dev/null || echo "")

        # Filter for plugin packages (exclude bundle and other non-VST packages)
        PLUGIN_PATHS=$(echo "$SYSTEM_REFS" | ${pkgs.gnugrep}/bin/grep -E "(serum2-|shaperbox3-|vst-)" | ${pkgs.gnugrep}/bin/grep -v "windows-plugin-bundle" | ${pkgs.gnugrep}/bin/grep -v "vamp-plugin" | ${pkgs.gnugrep}/bin/grep -v "thunar" || echo "")

        # Get current yabridge paths
        CURRENT_PATHS=$(${pkgs.yabridgectl}/bin/yabridgectl list 2>/dev/null || echo "")

        # Remove all old nix store paths from yabridge
        # This prevents duplicates from accumulating
        for old_path in $CURRENT_PATHS; do
          if echo "$old_path" | ${pkgs.gnugrep}/bin/grep -q "^/nix/store/"; then
            if ! echo "$PLUGIN_PATHS" | ${pkgs.gnugrep}/bin/grep -q "^$old_path$"; then
              echo "Removing old plugin path: $(basename "$old_path")"
              ${pkgs.yabridgectl}/bin/yabridgectl rm "$old_path" 2>/dev/null || true
            fi
          fi
        done

        # Add current plugins
        if [ -n "$PLUGIN_PATHS" ]; then
          for plugin_path in $PLUGIN_PATHS; do
            # Check if this path contains VST files
            if [ -d "$plugin_path" ] && (find "$plugin_path" -name "*.vst3" -o -name "*.dll" 2>/dev/null | ${pkgs.gnugrep}/bin/grep -q .); then
              # Only add if not already in the list
              if ! echo "$CURRENT_PATHS" | ${pkgs.gnugrep}/bin/grep -q "^$plugin_path$"; then
                PLUGIN_NAME=$(basename "$plugin_path" | ${pkgs.gnused}/bin/sed 's/-[0-9].*//')
                echo "Adding plugin: $PLUGIN_NAME"
                ${pkgs.yabridgectl}/bin/yabridgectl add "$plugin_path"
              fi
            fi
          done

          # Sync yabridge
          echo "Syncing yabridge..."
          ${pkgs.yabridgectl}/bin/yabridgectl sync
        else
          echo "No Windows plugins found in current system"
        fi
      '';

    in {
      home = {
        # Run yabridge setup when home configuration is activated
        activation.yabridgeSetup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          $DRY_RUN_CMD ${yabridgeSetup}
        '';

        # Ensure yabridge directories exist
        file = {
          ".vst3/yabridge/.keep".text = "";
          ".vst/yabridge/.keep".text = "";
          ".clap/yabridge/.keep".text = "";
        };
      };
    };
}
