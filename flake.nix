{
  description = "green";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    blueprint = {
      url = "github:numtide/blueprint";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
    cloudflare-speed-cli = {
      url = "github:kavehtehrani/cloudflare-speed-cli";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    let
      blueprintOutputs = inputs.blueprint {
        inherit inputs;

        # Keep the project-level layout under nix/ so app code and host code do
        # not get mixed together as the Raspberry Pi setup grows.
        prefix = "nix/";
      };
    in
    blueprintOutputs
    // inputs.flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system: {
      packages.cloudflare-speed-cli = inputs.cloudflare-speed-cli.packages.${system}.default;
    })
    // {
      nixosConfigurations.rpi4-01 = inputs.nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = {
          inherit inputs;
        };
        modules = [
          inputs.sops-nix.nixosModules.sops
          ./nix/hosts/rpi4-01/configuration.nix
        ];
      };
    };
}
