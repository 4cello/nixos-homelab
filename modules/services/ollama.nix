{
  flake.modules.nixos.ollama =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      nix.settings = {
        substituters = [ "https://cache.nixos-cuda.org" ];
        trusted-public-keys = [ "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M=" ];
      };

      services.ollama = {
        enable = true;
        package = pkgs.ollama-cuda;
        loadModels = [ "lfm2.5:8b" ];
      };

      services.open-webui = {
        enable = true;
        port = 23578;
        environment = {
          # ENABLE_PERSISTENT_CONFIG = "false";
          WEBUI_URL = "https://${config.homelab.services.open-webui.url}";
          # CORS_ALLOW_ORIGIN = "*";
          CORS_ALLOW_ORIGIN = "https://${config.homelab.services.open-webui.url}";
          ENABLE_OAUTH_SIGNUP = toString false;
          OAUTH_PROVIDER_NAME = "Pocket ID";
          OPENID_PROVIDER_URL = "${config.homelab.oidcUrl}/.well-known/openid-configuration";
          OAUTH_MERGE_ACCOUNTS_BY_EMAIL = toString true;

          # For group management, you can use the following variables:
          ENABLE_OAUTH_ROLE_MANAGEMENT = toString true;
          ENABLE_OAUTH_GROUP_MANAGEMENT = toString true;
          ENABLE_OAUTH_GROUP_CREATION = toString true;
          # Make sure these match the groups you created in Pocket ID
          OAUTH_ALLOWED_ROLES = "users,admins";
          OAUTH_ADMIN_ROLES = "admins";
          OAUTH_ROLES_CLAIM = "groups";
          OAUTH_SCOPES = "openid email profile groups";
          # WEBUI_SESSION_COOKIE_SAME_SITE = "lax";
          # WEBUI_AUTH_COOKIE_SAME_SITE = "lax";
          # Optional but useful variables:

          # So users are immediately added instead of being "pending"
          DEFAULT_USER_ROLE = "user";
          # Make Pocket ID the only auth method
          # comment out if you need access via password
          ENABLE_LOGIN_FORM = toString true;
          # Make Pocket ID the source of truth for the profile pictures
          OAUTH_UPDATE_PICTURE_ON_LOGIN = toString true;
        };
      };

      homelab.services.open-webui = {
        traefik.service.port = config.services.open-webui.port;
      };

    };
}
