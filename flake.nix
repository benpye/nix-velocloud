{
  description = "Support for the VeloCloud Edge 5X0.";
  inputs.nixos.url = "github:nixos/nixpkgs/nixos-23.11-small";

  outputs = { self, nixos }:
  let
    nixpkgsFor = system: import nixos { inherit system; overlays = [ self.overlay ]; };
  in rec {
    overlay = self: super: {
      velocloud-modules = self.callPackage ./velocloud-modules { };
    };

    nixosConfigurations = {
      installer = nixos.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          "${nixos}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
          ({pkgs, ...}: rec {
            # Make velocloud-modules available.
            nixpkgs.overlays = [ overlay ];

            # The VeloCloud Edge 5X0 uses ttyS1 for the USB miniB serial port.
            # Whilst serial will not work in the bootloader, the kernel will
            # use the correct port.
            boot.kernelParams = [ "console=ttyS1,115200n8" "acpi_enforce_resources=lax" ];

            # The patches apply against 5.15 - an LTS release.
            boot.kernelPackages = pkgs.linuxKernel.packages.linux_5_15;
            boot.extraModulePackages = [ (pkgs.velocloud-modules.override {
              kernel = boot.kernelPackages.kernel;
            }) ];

            # The required kernel modules for Ethernet, fan and LED control.
            boot.initrd.kernelModules = [ "lpc_ich" "velocloud-edge-5x0" ];
            boot.initrd.availableKernelModules = [ "gpio_ich" "iTCO_wdt" ];
          })
        ];
      };
    };

    packages.x86_64-linux = {
      inherit (nixpkgsFor "x86_64-linux") velocloud-modules;
    };
  };
}
