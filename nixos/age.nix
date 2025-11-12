{ ... }: {
  age.secrets = {
    network = {
      file = ../secrets/network.age;
      owner = "root";
      group = "root";
    };
  };
}
