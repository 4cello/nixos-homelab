{ ... }:
let
  name = "paperless";
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
        domain =
          let
            url = hl.services."${name}".url;
          in
          if lib.isString url then url else lib.elemAt url 0;
        mediaDir = mediaDir;
        database.createLocally = true;
        settings = {
          PAPERLESS_CONSUMER_RECURSIVE = true;
          PAPERLESS_CONSUMER_IGNORE_PATTERN = [
            ".DS_STORE/*"
            "desktop.ini"
          ];
          PAPERLESS_FILENAME_FORMAT = "{{ owner_username }}/{{ created_year }}/{{ correspondent }}/{{ title }}";
          PAPERLESS_FILENAME_FORMAT_REMOVE_NONE = true;
          PAPERLESS_OCR_LANGUAGE = "deu+eng";
          PAPERLESS_OCR_USER_ARGS = {
            optimize = 1;
            pdfa_image_compression = "lossless";
          };
          PAPERLESS_APPS = "allauth.socialaccount.providers.openid_connect";
        };
      };

      homelab.services."${name}" = {
        traefik.service.port = config.services.${name}.port;
      };
    };
}
