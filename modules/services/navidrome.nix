{ ... }:
let
  name = "navidrome";
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
        settings = {
          DataFolder = "${hl.mounts.fast}/apps/${name}";
          MusicFolder = "${hl.mounts.merged}/library/music";
          "ExtAuth.TrustedSources" = "0.0.0.0/0";
        };
      };

      homelab.services."${name}" = {
        traefik.service.port = config.services.${name}.settings.Port;
      };
    };
}
