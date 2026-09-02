{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.surge-downloader;
in
{
  options.services.surge-downloader = {
    enable = lib.mkEnableOption "surge-downloader headless server";

    package = lib.mkPackageOption pkgs "surge-downloader" { };

    token = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Api token for the server. If null, will use an auto-generated. To see what it is, run `surge token`";
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra arguments to pass to `surge server`";
    };
  };

  config = lib.mkIf cfg.enable {
    system.services.surge-downloader = {
      imports = [ pkgs.surge-downloader.services.default ];
      surge-downloader = { inherit (cfg) extraArgs package token; };
    };
  };

  meta.maintainers = with lib.maintainers; [
    ErmitaVulpe
  ];
}
