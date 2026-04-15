{ pkgs, ... }: {
  # Enable OpenTabletDriver
  hardware.opentabletdriver.enable = true;

  # Required by OpenTabletDriver
  hardware.uinput.enable = true;
  boot.kernelModules = [ "uinput" ];

  environment.systemPackages = with pkgs; [ krita opentabletdriver ];
}
