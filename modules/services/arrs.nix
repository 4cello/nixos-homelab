{ self, ... }: {
  flake.modules.nixos.arrs = {
    imports = with self.modules.nixos; [
      prowlarr
      sonarr
      radarr
      bazarr
      seerr
      unpackerr
    ];
  };
}
