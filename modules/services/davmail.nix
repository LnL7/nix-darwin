{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.services.davmail;
  configType = with types;
    oneOf [ (attrsOf configType) str int bool ] // {
      description = "davmail config type (str, int, bool or attribute set thereof)";
    };

  toStr = val: if isBool val then boolToString val else toString val;

  linesForAttrs = attrs: concatMap
    (
      name:
      let value = attrs.${name}; in
      if isAttrs value
      then map (line: name + "." + line) (linesForAttrs value)
      else [ "${name}=${toStr value}" ]
    )
    (attrNames attrs);
  configFile = pkgs.writeText "davmail.properties" (concatStringsSep "\n" (linesForAttrs cfg.config));
in
{
  options.services.davmail = {
    enable = mkEnableOption "MS Exchange gateway server";
    url = mkOption {
      type = types.str;
      description = "Outlook Web Access (OWA) URL to access the exchange server";
      example = "https://outlook.office365.com/EWS/Exchange.asmx";
    };
    config = mkOption {
      type = configType;
      default = { };
      description = ''
        Davmail configuration.
        See <http://davmail.sourceforge.net/serversetup.html>.
      '';
      example =
        literalExpression ''
          {
            davmail.server = true;
            davmail.allowRemote = false;
            davmail.disableUpdateCheck = true;
            davmail.enableKeepAlive = true;
            davmail.showStartupBanner = false;
            davmail.disableTrayActivitySwitch = true;
            davmail.disableGuiNotifications = true;
          }
        '';
    };
  };

  config = mkIf cfg.enable {
    services.davmail.config = {
      davmail = mapAttrs (name: mkDefault) {
        server = true;
        disableUpdateCheck = true;
        logFilePath = "/var/log/davmail/davmail.log";
        logFileSize = "1MB";
        mode = "auto";
        url = cfg.url;
        caldavPort = 1080;
        imapPort = 1143;
        ldapPort = 1389;
        popPort = 1110;
        smtpPort = 1025;
      };
      log4j = {
        logger.davmail = mkDefault "WARN";
        logger.httpclient.wire = mkDefault "WARN";
        logger.org.apache.commons.httpclient = mkDefault "WARN";
        rootLogger = mkDefault "WARN";
      };
    };

    launchd.user.agents.davmail = {
      serviceConfig.ProgramArguments = "${pkgs.davmail}/bin/davmail ${configFile}";
      serviceConfig.RunAtLoad = true;
      serviceConfig.KeepAlive = true;
    };
  };
}
