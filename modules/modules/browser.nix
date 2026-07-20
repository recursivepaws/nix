{
  den.aspects.browser = {
    homeManager =
      { pkgs, config, ... }:
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

        # Separate profile/launcher for WebGPU use with --enable-features=Vulkan
        xdg.desktopEntries.google-chrome-webgpu = {
          name = "Google Chrome (WebGPU)";
          comment = "Google Chrome with Vulkan/WebGPU enabled, in a separate profile";
          icon = "google-chrome";
          terminal = false;
          type = "Application";
          categories = [
            "Network"
            "WebBrowser"
          ];
          exec = "${pkgs.google-chrome}/bin/google-chrome-stable --user-data-dir=${config.home.homeDirectory}/.config/google-chrome-webgpu --enable-features=Vulkan %U";
        };
      };
  };
}
