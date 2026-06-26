{
  description = "bar207 - A Quickshell-based status bar";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    quickshell.url = "github:quickshell-mirror/quickshell/v0.3.0";
    quickshell.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, quickshell, ... }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      pkgsFor = system: import nixpkgs { inherit system; };
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = pkgsFor system;
          qsPkg = quickshell.packages.${system}.default;
        in {
          default = pkgs.stdenv.mkDerivation {
            pname = "bar207";
            version = "main";

            src = ./.;

            nativeBuildInputs = [
              pkgs.makeWrapper
              pkgs.qt6.wrapQtAppsHook
            ];

            buildInputs = [
              pkgs.qt6.qt5compat
            ];

            installPhase = ''
              runHook preInstall

              mkdir -p $out/share/bar207
              cp -r *.qml $out/share/bar207/

              mkdir -p $out/bin

              makeQtWrapper ${qsPkg}/bin/quickshell $out/bin/bar207 \
                --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.bash pkgs.networkmanager pkgs.gnugrep ]} \
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

      nixosModules.default = { config, lib, pkgs, ... }:
        let
          cfg = config.programs.bar207;
        in {
          options.programs.bar207 = {
            enable = lib.mkEnableOption "bar207 status bar";

            package = lib.mkOption {
              type = lib.types.package;
              default = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
              description = "The bar207 package to use.";
            };

            showBatteryPercent = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Show battery percentage next to the battery icon in the bar.";
            };

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
              configFile = pkgs.writeText "Config.qml" ''
                pragma Singleton
                import Quickshell
                import QtQuick

                Singleton {
                  id: root
                  readonly property color background: "${cfg.colors.background}"
                  readonly property color selection:  "${cfg.colors.selection}"
                  readonly property color foreground: "${cfg.colors.foreground}"
                  readonly property color inactive:   "${cfg.colors.inactive}"
                  readonly property bool showBatteryPercent: ${if cfg.showBatteryPercent then "true" else "false"}
                }
              '';
              finalPackage = cfg.package.overrideAttrs (oldAttrs: {
                postInstall = (oldAttrs.postInstall or "") + ''
                  cp ${configFile} $out/share/bar207/Config.qml
                '';
              });
            in {
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