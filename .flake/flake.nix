{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

    zephyr.url = "github:zephyrproject-rtos/zephyr/v3.5.0";
    zephyr.flake = false;

    zephyr-nix.url = "github:adisbladis/zephyr-nix";
    zephyr-nix.inputs.nixpkgs.follows = "nixpkgs";
    zephyr-nix.inputs.zephyr.follows = "zephyr";
  };

  outputs = { self, nixpkgs, zephyr-nix, ... }: let
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
    zephyr = zephyr-nix.packages.x86_64-linux;
  in {
    devShells.x86_64-linux.default = pkgs.mkShell {
      packages = with pkgs; [
        zephyr.pythonEnv
        (zephyr.sdk.override { targets = [ "arm-zephyr-eabi" ]; })
        zephyr.hosttools-nix

        cmake
        ninja
        just
        yq
      ];
    };
  };
}
