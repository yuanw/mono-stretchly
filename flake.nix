{
  inputs = {
    # for macos
    nixpkgs.url = "nixpkgs/nixos-unstable";
    #nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    flake-parts.url = "github:hercules-ci/flake-parts";
    haskell-flake.url = "github:srid/haskell-flake";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
    };
    pre-commit = {
      url = "github:cachix/pre-commit-hooks.nix";
    };
    devshell.url = "github:numtide/devshell";
    monomer = {
      url = "github:fjvallarino/monomer";
      flake = false;
    };
    nanovg = {
      url = "github:cocreature/nanovg-hs";
      flake = false;
    };
  };
  outputs = inputs@{ nixpkgs, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = nixpkgs.lib.systems.flakeExposed;
      imports = [
        inputs.haskell-flake.flakeModule
        inputs.pre-commit.flakeModule
        inputs.treefmt-nix.flakeModule
        inputs.devshell.flakeModule
      ];

      perSystem = { self', pkgs, config, system, ... }: {
        _module.args = import inputs.nixpkgs {
          inherit system;
          overlays = [
            (_self: super: {
              # Stork is marked as broken on intel mac, but it does work.
              # Unfortunately we cannot test this code PATH due to lack of CI for intel mac (#335).
              monomer = super.monomer.overrideAttrs (_oa: {
                meta.broken = false;
                meta.platforms = [ system ];
                meta.badPlatforms = [ ];
              });
              nanovg = super.nanovg.overrideAttrs (_oa: {
                meta.broken = false;
                meta.platforms = [ system ];
                meta.badPlatforms = [ ];
              });
            })
          ];
        };
        # Typically, you just want a single project named "default". But
        # multiple projects are also possible, each using different GHC version.
        haskellProjects.default = {
          # The base package set representing a specific GHC version.
          # By default, this is pkgs.haskellPackages.
          # You may also create your own. See https://zero-to-flakes.com/haskell-flake/package-set
          # basePackages = pkgs.haskellPackages;

          # Extra package information. See https://zero-to-flakes.com/haskell-flake/dependency
          #
          # Note that local packages are automatically included in `packages`
          # (defined by `defaults.packages` option).
          #
          packages = {
            #monomer.source = inputs.monomer;
            #nanovg.source = inputs.nanovg;
          };
          settings = {
            # aeson = {
            #   check = false;
            # };
            #monomer = {
            #haddock = false;
            #broken = false;
            #badPlatforms = [ ];
            #};
          };
          autoWire = [ "packages" "checks" ]; # Wire all but the devShell

          devShell = {
            # Enabled by default
            enable = true;

            # Programs you want to make available in the shell.
            # Default programs can be disabled by setting to 'null'
            tools = hp: { fourmolu = hp.fourmolu; };

            hlsCheck.enable = true;
          };
        };
        treefmt.imports = [ ./treefmt.nix ];
        formatter = config.treefmt.build.wrapper;
        # haskell-flake doesn't set the default package, but you can do it here.
        # Inside perSystem
        packages.default = pkgs.haskell.lib.justStaticExecutables self'.packages.mono-stretchly;
        pre-commit.settings.hooks.treefmt.enable = true;

        devshells.default = {
          devshell.startup.git.text = config.pre-commit.installationScript;
          env = [
            {
              name = "HTTP_PORT";
              value = 8080;
            }
          ];
          commands = [
            {
              help = "print hello";
              name = "fmt";
              command = "nix fmt";
            }
          ];
          packagesFrom = [
            config.treefmt.build.devShell
            config.pre-commit.devShell
            config.haskellProjects.default.outputs.devShell
          ];
        };
      };
    };
}
