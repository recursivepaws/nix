{ inputs, ... }: {
  flake-file.inputs.obsidian-extensions = {
    url = "github:karaolidis/nix-obsidian-extensions";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.obsidian = {
    homeManager = { pkgs, ... }: {
      nixpkgs.overlays = with inputs; [
        obsidian-extensions.overlays.default
      ];
      programs.obsidian = {
        enable = true;
        defaultSettings = {
          communityPlugins = with pkgs.obsidianPlugins; [
            obsidian-git
            dataview
            table-editor-obsidian
            sansconverter
            omnisearch
            templater-obsidian
            obsidian-linter
          ];
          themes = with pkgs.obsidianThemes; [
            carbon
          ];
        };
      };
    };
  };
}
