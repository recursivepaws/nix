{ den, lib, ... }:
{
  den.aspects.custom-yabridge =
    let
      overlay = final: prev: {
        # yabridgectl =
        #   prev.yabridgectl.override { wine = prev.wineWowPackages.stableFull; };
        # yabridge = prev.yabridge.override { wineWowPackages = true; };
        # yabridge = prev.yabridge.override { wineWow64Packages = prev.wine; };
        # yabridgectl = prev.yabridgectl.override {
        #   wineWow64Packages = prev.wine;
        #   yabridge = final.yabridge;
        # };
        # yabridge-custom = (prev.yabridge.override {
        #   wine = prev.wine-experimental;
        # }).overrideAttrs (oldAttrs: {
        #   pname = "yabridge";
        #   version = "6.0.0-embedding-beta";
        #
        #   src = prev.fetchFromGitHub {
        #     owner = "robbert-vdh";
        #     repo = "yabridge";
        #     rev = "945528cd7f898d717d772b93f939343dad122d91";
        #     hash = "sha256-qjyBnwdd/yRIiiAApHyxc/XkkEwB33YP0GpIjG4Upro=";
        #   };
        #
        #   patches = [ ];
        #
        #   # Turn off 32-bit bit bridge
        #   mesonFlags = (builtins.filter (f: !lib.hasPrefix "-Dbitbridge=" f)
        #     (oldAttrs.mesonFlags or [ ])) ++ [ "-Dbitbridge=false" ];
        #
        #   installPhase = ''
        #     runHook preInstall
        #     mkdir -p $out/bin $out/lib
        #
        #     # Only install the 64-bit host binaries
        #     cp yabridge-host.exe $out/bin/ || true
        #     cp yabridge-host.exe.so $out/bin/ || true
        #
        #     for type in vst2 vst3 clap; do
        #       src=$(ls *yabridge-$type.so 2>/dev/null | head -n 1)
        #       if [ -n "$src" ]; then
        #         cp "$src" "$out/lib/libyabridge-$type.so"
        #         ln -s "$out/lib/libyabridge-$type.so" "$out/lib/libyabridge-chainloader-$type.so"
        #       fi
        #     done
        #
        #     runHook postInstall
        #   '';
        #
        #   doCheck = false;
        # });
      };
    in
    {
      includes = [ den.aspects.custom-wine ];
      nixos.nixpkgs.overlays = [ overlay ];
      homeManager.nixpkgs.overlays = [ overlay ];
    };
}
