{
  den.aspects.bitwig-theme-editor = {
    homeManager = { pkgs, lib, ... }:
      let
        bitwig-theme-editor = let
          description = "Bitwig Theme Editor";
          pname = "bitwig-theme-editor";
          version = "2.3.1";
        in pkgs.stdenv.mkDerivation rec {
          inherit pname version;
          src = let filename = "${pname}-${version}-hotfix.jar";
          in pkgs.fetchurl {
            name = filename;
            url =
              "https://github.com/Berikai/${pname}/releases/download/${version}/${filename}";
            hash = "sha256-Fkz1s5DY8Ey3Il7CBHNmV87JyJ8clSEF1CltVwlq3/w=";
          };

          nativeBuildInputs = with pkgs; [ jre makeWrapper copyDesktopItems ];

          # Skip the normal build phases — there's nothing to compile
          dontUnpack = true;
          dontBuild = true;

          desktopItems = [
            (pkgs.makeDesktopItem {
              name = pname;
              exec = pname;
              icon = pname;
              desktopName = description;
              comment = description;
              categories = [ "Utility" ];
            })
          ];

          installPhase = ''
            # Install the JAR
            mkdir -p $out/share/java
            cp $src $out/share/java/${pname}.jar

            # Create a wrapper script in bin/
            mkdir -p $out/bin
            makeWrapper ${pkgs.jre}/bin/java $out/bin/${pname} \
              --add-flags "-jar $out/share/java/${pname}.jar"
          '';

          meta = {
            description = description;
            mainProgram = pname;
          };
        };
      in { home.packages = [ bitwig-theme-editor ]; };
  };
}
