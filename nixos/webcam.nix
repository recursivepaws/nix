{ config, pkgs, ... }: {
  environment.systemPackages = with pkgs; [ v4l-utils cameractrls ];
  boot.extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
  boot.kernelModules = [ "v4l2loopback" ];
  boot.extraModprobeConfig = ''
    options v4l2loopback devices=2 video_nr=10,11 card_label="VirtualCam A","VirtualCam B"
  '';
}
