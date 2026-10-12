# enables `nix run .#vm`.
# test config edits in a VM instead of rebooting each time.
{ inputs, den, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages.vm = pkgs.writeShellApplication {
        name = "vm";
        text =
          let
            host = inputs.self.nixosConfigurations.hericium.config;
          in
          ''
            ${host.system.build.vm}/bin/run-${host.networking.hostName}-vm "$@"
          '';
      };
    };

  den.aspects.hericium = {
    includes = [ (den.provides.tty-autologin "vera") ];
    nixos = {
      virtualisation.vmVariant = {
        environment.sessionVariables = {
          LIBGL_ALWAYS_SOFTWARE = "1";
          MESA_GL_VERSION_OVERRIDE = "4.5";
        };
        users.users.vera.initialPassword = "vm";
        # services.displayManager.autoLogin = {
        #   enable = true;
        #   user = "vera";
        # };
        virtualisation.qemu.options = [
          "-device virtio-vga"
          "-display gtk,gl=on"
        ];
      };
    };
  };
}
