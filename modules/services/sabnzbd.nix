{ ... }:
let
  name = "sabnzbd";
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
        user = hl.user.name;
        group = hl.group.name;
        allowConfigWrite = true;
        settings = {
          misc =
            let
              download_dir = "${hl.mounts.fast}/cache/${name}";
            in
            {
              port = 9595;
              download_dir = "${download_dir}/incomplete";
              complete_dir = "${download_dir}/complete";
              host_whitelist = "${hl.services."${name}".url}";
            };
          categories = builtins.listToAttrs (
            map
              (
                name:
                lib.nameValuePair name {
                  inherit name;
                  order = 0;
                  script = "Default";
                  pp = "";
                  dir = "";
                  newzbin = "";
                  priority = -100;
                }
              )
              [
                "*"
                "movies"
                "tv"
                "audio"
                "software"
                "prowlarr"
              ]
          );
        };
      };

      homelab.services."${name}" = {
        traefik.service.port = config.services.${name}.settings.misc.port;
        traefik.middlewares = [ "tinyauth" ];
      };
    };
}
