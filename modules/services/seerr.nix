{ ... }:
let
  name = "seerr";
in
{
  flake.modules.nixos."${name}" =
    { config, lib, ... }:
    let
      hl = config.homelab;
    in
    {
      services.${name} = {
        enable = true;
        configDir = "${hl.mounts.config}/${name}";
      };

      systemd.services."${name}".serviceConfig = {
        DynamicUser = lib.mkForce false;
        User = hl.user.name;
        Group = hl.group.name;
        ReadWritePaths = [ config.services.${name}.configDir ];
      };

      homelab.services."${name}" = {
        traefik.service.port = config.services.${name}.port;
      };
    };
}
