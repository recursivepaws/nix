{
  den.default =
    let
      overlay = final: prev: {
        # Elevate a GUI app via polkit (noctalia agent shows the prompt).
        # Forward the whole environment so HOME-based gtk theming survives.
        pkexec-gui = final.writeShellScriptBin "pkexec-gui" ''
          mapfile -d "" vars < <(env -0)
          exec pkexec env "''${vars[@]}" "$@"
        '';

        # wrapSudo pkg: same package, but every binary elevates via pkexec-gui.
        # Desktop files with an absolute store-path Exec would bypass the wrapper.
        wrapSudo =
          pkg:
          final.symlinkJoin {
            name = "${final.lib.getName pkg}-pkexec";
            paths = [ pkg ];
            postBuild = ''
              for f in $out/bin/*; do
                name=$(basename "$f")
                rm -f "$f"
                cat > "$f" <<EOF
              #!${final.runtimeShell}
              exec ${final.pkexec-gui}/bin/pkexec-gui ${pkg}/bin/$name "\$@"
              EOF
                chmod +x "$f"
              done
            '';
          };
      };
    in
    {
      nixos.nixpkgs.overlays = [ overlay ];
      homeManager.nixpkgs.overlays = [ overlay ];
    };
}
