{ ... }:
let
  overlay = final: prev: {
    wine-experimental = prev.wineWow64Packages.waylandFull.overrideAttrs
      (oldAttrs: {
        meta = oldAttrs.meta // {
          description = "wayland version of wine (Wine 11)";
        };
      });
    wine-stable = prev.wineWow64Packages.stableFull.overrideAttrs (oldAttrs: {
      meta = oldAttrs.meta // {
        description = "stable version of wine (Wine 11)";
      };
    });
    wine-fallback = prev.wineWow64Packages.yabridge.overrideAttrs (oldAttrs: {
      meta = oldAttrs.meta // {
        description = "older version of wine (Wine 9.21)";
      };
    });

    /* wine-experimental = prev.wineWow64Packages.full.overrideAttrs (oldAttrs: {
         version = "11.0-giang17";
         src = prev.fetchFromGitHub {
           owner = "giang17";
           repo = "wine";
           rev = "588c5e1942cb68d01e14bf17581a653a668ec18d";
           hash = "sha256-eH26xBjaFyxbKorguAMx5LPsj/II8Qe7BBKR+Y7qPIQ=";
         };
         meta = oldAttrs.meta // {
           description = "experimental version of wine ";
         };
         configureFlags = (oldAttrs.configureFlags or [ ])
           ++ [ "--enable-archs=i386,x86_64" ];

         buildInputs = (oldAttrs.buildInputs or [ ]) ++ [
           prev.pkgsi686Linux.xorg.libX11
           prev.pkgsi686Linux.wayland
           prev.pkgsi686Linux.libxkbcommon
         ];

         # llvm is only needed for the host; winebuild handles PE indexing itself
         nativeBuildInputs = oldAttrs.nativeBuildInputs or [ ];

         postInstall = (oldAttrs.postInstall or "") + ''
           echo "Re-indexing Wine archives..."

           # ELF archives — only x86_64-unix exists in Wine 11 wow64 mode
           for dir in x86_64-unix i386-unix; do
             full="$out/lib/wine/$dir"
             [ -d "$full" ] || continue
             find "$full" -name "*.a" -print0 \
               | xargs -0 -r ${prev.binutils}/bin/ranlib
           done

           # PE import libraries — winebuild --lib re-indexes in-place
           for arch in i386-windows x86_64-windows; do
             dir="$out/lib/wine/$arch"
             [ -d "$dir" ] || continue
             echo "  indexing $arch..."
             for a in "$dir"/*.a; do
               [ -f "$a" ] || continue
               $out/bin/winebuild --lib -o "$a" "$a" 2>/dev/null || true
             done
           done

           echo "Archive indexing complete."
         '';

         patches = [ ];
         prePatch = "";
       });
    */
  };
in {
  den.aspects.custom-wine = {
    nixos.nixpkgs.overlays = [ overlay ];
    homeManager.nixpkgs.overlays = [ overlay ];
  };
}
