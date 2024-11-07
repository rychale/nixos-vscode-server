#{
#  config,
#  lib,
#  pkgs,
#  ...
#}: let
#  services = import ./module.nix {inherit config lib pkgs;};
#in {
#  systemd.user =
#    lib.mapAttrs (name: description: serviceConfig: {
#      inherit description serviceConfig;
#      wantedBy = ["default.target"];
#    })
#    services;
#}
import ./module.nix ({
  name,
  description,
  serviceConfig,
}: {
  systemd.user.services.${name} = {
    inherit description serviceConfig;
    wantedBy = [ "default.target" ];
  };
})
