{
  flake.modules.nixos.homelab =
    { config, lib, ... }:
    {
      options.homelab.services = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.submodule (
            { name, ... }: {
              options = {
                enable = lib.mkOption {
                  type = lib.types.bool;
                  # Yes, a service is enabled by default if the module is loaded.
                  # if for some reason the module needs to be loaded, service can be disabled manually
                  default = true;
                };
                url = lib.mkOption {
                  default = "${name}.${config.homelab.baseDomain}";
                  type = lib.types.oneOf [
                    lib.types.str
                    (lib.types.listOf lib.types.str)
                  ];
                };
                monitoredServices = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [ name ];
                };

                traefik = lib.mkOption {
                  default = { };
                  type = lib.types.submodule {
                    options = {
                      enable = lib.mkOption {
                        type = lib.types.bool;
                        default = true; # see global enabled
                      };
                      service = lib.mkOption {
                        type = lib.types.oneOf [
                          (lib.types.nullOr lib.types.str)
                          (lib.types.submodule {
                            options.port = lib.mkOption { type = lib.types.port; };
                          })
                        ];
                        default = null;
                      };
                      middlewares = lib.mkOption {
                        type = lib.types.listOf lib.types.str;
                        default = [ ];
                      };
                    };
                  };
                };

                homepage = lib.mkOption {
                  default = { };
                  type = lib.types.submodule {
                    options = {
                      enable = lib.mkEnableOption "Homepage entry for ${name}";
                      description = lib.mkOption {
                        type = lib.types.str;
                        default = "${name}";
                      };
                      category = lib.mkOption {
                        type = lib.types.nullOr lib.types.str;
                        default = null;
                      };
                      icon = lib.mkOption {
                        type = lib.types.nullOr lib.types.str;
                        default = null;
                      };
                    };
                  };
                };

                backup = lib.mkOption {
                  default = { };
                  type = lib.types.submodule {
                    options = {
                      enable = lib.mkEnableOption "Backups for ${name}";
                      configDir = lib.mkOption {
                        type = lib.types.nullOr lib.types.str;
                        default = null;
                      };
                      dataDir = lib.mkOption {
                        type = lib.types.nullOr lib.types.str;
                        default = null;
                      };
                    };
                  };
                };
              };
            }
          )
        );
      };
    };
}
