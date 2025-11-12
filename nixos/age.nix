{ ... }: {
  age.secrets = {
    startup = {
      file = ../secrets/startup.age;
      owner = "root";
      group = "root";
    };
    # network = {
    #   file = ../secrets/network.age;
    # };
  };
}
