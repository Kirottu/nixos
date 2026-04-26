{
  description = "My NixOS config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # nixpkgs-wivrn.url = "github:NixOS/nixpkgs/e64102a9f7f35ef2cddaea6f09c1f5077b948296";
    nixpkgs-small.url = "github:NixOS/nixpkgs/nixos-unstable-small";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # niri = {
    #   url = "github:sodiboo/niri-flake";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    niri-nix.url = "git+https://codeberg.org/BANanaD3V/niri-nix";
    niri.url = "github:niri-wm/niri";

    ironbar = {
      url = "github:JakeStanger/ironbar";
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

    wrappers = {
      url = "github:lassulus/wrappers";
    };

    # import-tree.url = "github:vic/import-tree";

    impermanence.url = "github:nix-community/impermanence";

    codel = {
      # url = "git+ssh://git@zimward.moe/~/lsp?ref=main";
      url = "github:zimward/codel";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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
      url = "github:anyrun-org/anyrun";
      # url = "github:sents/anyrun/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    wivrn-connection-manager = {
      url = "github:Kirottu/wivrn-connection-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    personal-site = {
      url = "github:Kirottu/kirottu.com";
      flake = false;
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
      myPkgs = lib.trace (import ./packages { inherit lib; }) (import ./packages { inherit lib; });
      inherit (inputs.nixpkgs.lib.fileset) toList fileFilter;
      import-tree =
        path:
        toList (fileFilter (file: file.hasExt "nix" && !(inputs.nixpkgs.lib.hasPrefix "_" file.name)) path);

      modules = import-tree ./modules;
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
          ]
          ++ modules;
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
          ]
          ++ modules;
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
          ]
          ++ modules;
        };
        hell-of-harold = inputs.nixpkgs-small.lib.nixosSystem {
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
            ./hosts/hell-of-harold
            inputs.private.nixosModules.hell-of-harold
          ]
          ++ modules;
        };
      };
    };
}
