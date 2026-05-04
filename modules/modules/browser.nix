{
  den.aspects.browser = {
    homeManager = { pkgs, ... }:
      # let
      #   bilibili-to-english = pkgs.fetchFromGitHub {
      #     owner = "LazyScar";
      #     repo = "BiliBili-To-English";
      #     rev = "main";
      #     hash = "sha256-JVvcSLa+ysFIsGiRGWcYDy0tlrx2Jq4KU66DTocO3Z4=";
      #   };
      # in 
      {
        programs.google-chrome = {
          enable = true;
          # commandLineArgs = [ "--load-extension=${bilibili-to-english}" ];
        };
      };
  };
}
