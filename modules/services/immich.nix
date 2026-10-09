{ ... }:
let
  name = "immich";
in
{
  flake.modules.nixos."${name}" =
    { config, lib, ... }:
    let
      hl = config.homelab;
      user = config.services.${name}.user;
      mediaDir = "${hl.mounts.fast}/personal/${name}";
    in
    {
      services.${name} = {
        enable = true;
        group = hl.group.name;
        host = "127.0.0.1"; # to prevent using the IPv6 loopback
        mediaLocation = mediaDir;
        settings = {
          logging.level = "debug";
          oauth = {
            enabled = true;
            issuerUrl = hl.oidcUrl;
          };
        };
      };

      systemd.tmpfiles.rules = [ "d ${mediaDir} 0775 ${user} ${hl.group.name} - -" ];
      users.users."${user}".extraGroups = [
        "video"
        "render"
      ];

      homelab.services."${name}" = {
        traefik.service.port = config.services.${name}.port;
      };
    };
}
