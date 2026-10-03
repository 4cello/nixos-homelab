{ ... }:
let
  name = "jellyfin";
in
{
  flake.modules.nixos."${name}" =
    { config, ... }:
    let
      hl = config.homelab;
    in
    {
      services.${name} = {
        enable = true;
        user = hl.user.name;
        group = hl.group.name;
        hardwareAcceleration.enable = true;
        configDir = "${hl.mounts.config}/jellyfin";
        dataDir = "${hl.mounts.fast}/apps/jellyfin";
      };
      # TODO: implement https://github.com/jon4hz/jellyfin-plugin-discontinue-watching with traefik

      homelab.services."${name}" = {
        traefik.service.port = 8096;
      };
    };
}
