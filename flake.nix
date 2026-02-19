{
  description = "My NixOS config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stremio.url = "github:NixOS/nixpkgs/b6a8526db03f735b89dd5ff348f53f752e7ddc8e";
    # nixpkgs-wivrn.url = "github:NixOS/nixpkgs/e64102a9f7f35ef2cddaea6f09c1f5077b948296";
    nixpkgs-small.url = "github:NixOS/nixpkgs/nixos-unstable-small";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs-xr = {
      url = "github:nix-community/nixpkgs-xr";
    };

    impermanence.url = "github:nix-community/impermanence";

    # My bits and bops
    yand = {
      url = "github:Kirottu/yand";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    persist-retro.url = "github:Kirottu/persist-retro";

    kidex = {
      url = "github:Kirottu/kidex";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hm-modules = {
      url = "github:Kirottu/hm-modules";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ctrld = {
      url = "github:Kirottu/ctrld-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    system76-scheduler-niri = {
      url = "github:Kirottu/system76-scheduler-niri";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    anyrun = {
      # url = "github:anyrun-org/anyrun";
      url = "github:sents/anyrun/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    wivrn-connection-manager = {
      url = "github:Kirottu/wivrn-connection-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # anyrun-master = {
    #   url = "github:anyrun-org/anyrun";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    private = {
      url = "git+ssh://git@github.com/Kirottu/nixos-private";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs =
    inputs:
    let
      # Overlay with some utilities
      lib = import ./lib { inherit inputs lib; };
      privateInputs = inputs.private.inputs;
      myPkgs = import ./packages;
    in
    {
      nixosConfigurations = {
        church-of-harold = lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit
              inputs
              lib
              privateInputs
              myPkgs
              ;
          };
          modules = [
            ./hosts/church-of-harold
            inputs.private.nixosModules.church-of-harold
          ];
        };
        missionary-of-harold = lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit
              inputs
              lib
              privateInputs
              myPkgs
              ;
          };
          modules = [
            ./hosts/missionary-of-harold
            inputs.private.nixosModules.missionary-of-harold
          ];
        };
        overwatch-of-harold = inputs.nixpkgs-small.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit
              inputs
              lib
              privateInputs
              myPkgs
              ;
          };
          modules = [
            ./hosts/overwatch-of-harold
            inputs.private.nixosModules.overwatch-of-harold
          ];
        };
      };
    };
}
