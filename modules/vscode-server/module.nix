moduleConfig: {
  config,
  lib,
  pkgs,
  ...
}: with lib; {
  options.services.vscode-server = {

    services = mkOption {
      type = types.attrs;
      internal = true;
      readonly = true;
    };

    instances = with lib; with types; mkOption {
      type = types.attrsOf (submodule ({config, ...}: {
          options = {
            enableFHS = mkEnableOption "a FHS compatible environment";

            nodejsPackage = mkOption {
              type = nullOr package;
              default = null;
              example = pkgs.nodejs_20;
              description = ''
                Option to specify a particular Node.js version instead of using the version provided by the VSCode Server.
              '';
            };

            extraRuntimeDependencies = mkOption {
              type = listOf package;
              default = [];
              description = ''
                A list of extra packages to use as runtime dependencies.
                It is used to determine the RPATH to automatically patch ELF binaries with,
                or when a FHS compatible environment has been enabled,
                to determine its extra target packages.
              '';
            };

            installPath = mkOption {
              type = str;
              default = ["$HOME/.vscode-server"];
              example = ["$HOME/.vscode-server-oss"];
              description = ''
                An install path of the VSCode Server.
              '';
            };

            postPatch = mkOption {
              type = lines;
              default = "";
              description = ''
                Lines of Bash that will be executed after the VSCode Server installation has been patched.
                This can be used as a hook for custom further patching.
              '';
            };
          };

          config = {
            nodejsPackage = mkIf config.enableFHS (mkDefault pkgs.nodejs_20);
          };
        }));

      default = {
        "vscode" = {
          installPath = "$HOME/.vscode-server";
        };
      };

      description = "A list of VSCode Server instances";
    };
  };

  config = let
    cfg = config.services.vscode-server.instances;

    createService = instanceName: instanceCfg: let
      auto-fix-vscode-server = pkgs.callPackage ../../pkgs/auto-fix-vscode-server.nix instanceCfg;
    in {
      name = "auto-fix-vscode-server-${instanceName}";
      description = "A VSCode Server for ${instanceCfg.installPath}";
      serviceConfig = {
        Restart = "always";
        RestartSec = 0;
        ExecStart = "${auto-fix-vscode-server}/bin/auto-fix-vscode-server";
      };
    };

    services = [0]; #mapAttrsToList (instanceName: instanceCfg: moduleConfig (createService instanceName instanceCfg)) cfg;
  in
    # {services.vscode-server.services = services;};
    builtins.head services;
}
