{ inputs, ... }: {
  # NOTE: nice reference https://github.com/nyxar77/homeconfig/blob/15ce1d4d2ee505b0701c34c0b59972146561c9fc/home/modules/apps/obsidian.nix

  flake-file.inputs.obsidian-extensions = {
    url = "github:karaolidis/nix-obsidian-extensions";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.obsidian = {
    homeManager = { pkgs, ... }: {
      nixpkgs.overlays = with inputs; [
        obsidian-extensions.overlays.default
      ];
      programs.git.ignores = [
        ".obsidian/"
      ];
      programs.obsidian = {
        enable = true;
        vaults = {
          # notes = {
          #   target = "Documents/notes";
          # };
          tickets = {
            target = ".claude/tickets";
          };
        };
        defaultSettings = {
          app = {
            vimMode = true;
            trashOption = "system";
            defaultViewMode = "preview";
          };
          communityPlugins = with pkgs.obsidianPlugins; [
            obsidian-git
            obsidian-tasks-plugin
            dataview
            table-editor-obsidian
            sansconverter
            omnisearch
            templater-obsidian
            obsidian-linter
            heatmap-tracker
          ];
          themes = with pkgs.obsidianThemes; [
            carbon
          ];
        };
      };
    };
  };
}
