{
  description = "bar207 - A Quickshell-based status bar";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    
    # Using the bleeding-edge Quickshell as requested
    quickshell.url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
    quickshell.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, quickshell, ... }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      pkgsFor = system: import nixpkgs { inherit system; };
    in
    {
      # 1. The Package Definition
      packages = forAllSystems (system:
        let
          pkgs = pkgsFor system;
          qsPkg = quickshell.packages.${system}.default;
        in {
          default = pkgs.stdenv.mkDerivation {
            pname = "bar207";
            version = "main";
            
            src = ./.;

            nativeBuildInputs = [ pkgs.makeWrapper ];

            installPhase = ''
              runHook preInstall

              mkdir -p $out/share/bar207
              cp -r *.qml $out/share/bar207/

              mkdir -p $out/bin
              makeWrapper ${qsPkg}/bin/quickshell $out/bin/bar207 \
                --add-flags "-p $out/share/bar207/shell.qml"

              runHook postInstall
            '';
          };
        });

      apps = forAllSystems (system: {
        default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/bar207";
        };
      });

      # 3. The NixOS Module (Now with Color Theming!)
      nixosModules.default = { config, lib, pkgs, ... }:
        let
          cfg = config.programs.bar207;
        in {
          options.programs.bar207 = {
            enable = lib.mkEnableOption "bar207 status bar";
            
            package = lib.mkOption {
              type = lib.types.package;
              default = self.packages.${pkgs.system}.default;
              description = "The bar207 package to use.";
            };

            # --- NEW: Color Config Options ---
            colors = {
              background = lib.mkOption {
                type = lib.types.str;
                default = "#1f1d2e";
                description = "Background color (hex code)";
              };
              selection = lib.mkOption {
                type = lib.types.str;
                default = "#363151";
                description = "Selection/Highlight color (hex code)";
              };
              foreground = lib.mkOption {
                type = lib.types.str;
                default = "#c4a7e7";
                description = "Foreground/Text/Icon color (hex code)";
              };
              inactive = lib.mkOption {
                type = lib.types.str;
                default = "#6e6a86";
                description = "Inactive/Muted item color (hex code)";
              };
            };
          };

          config = lib.mkIf cfg.enable (
            let
              # 1. Dynamically generate the Colors.qml file based on the config
              customColorsFile = pkgs.writeText "Colors.qml" ''
                pragma Singleton
                import Quickshell
                import QtQuick

                Singleton {
                  id: root
                  readonly property color background: "${cfg.colors.background}"
                  readonly property color selection:  "${cfg.colors.selection}"
                  readonly property color foreground: "${cfg.colors.foreground}"
                  readonly property color inactive:   "${cfg.colors.inactive}"
                }
              '';

              # 2. Override the original package to inject our custom colors file
              finalPackage = cfg.package.overrideAttrs (oldAttrs: {
                postInstall = (oldAttrs.postInstall or "") + ''
                  # Overwrite the default Colors.qml with our custom generated one
                  cp ${customColorsFile} $out/share/bar207/Colors.qml
                '';
              });
            in {
              # 3. Install and run the fully themed package
              environment.systemPackages = [ finalPackage ];

              systemd.user.services.bar207 = {
                description = "bar207 Quickshell Status Bar";
                wantedBy = [ "graphical-session.target" ];
                partOf = [ "graphical-session.target" ];
                after = [ "graphical-session.target" ];
                
                serviceConfig = {
                  ExecStart = "${finalPackage}/bin/bar207";
                  Restart = "on-failure";
                  RestartSec = "3";
                };
              };
            }
          );
        };
    };
}