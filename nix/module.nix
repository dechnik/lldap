self: { config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.lldap;
  configFile = pkgs.writeText "lldap_config.toml" ''
    ldap_host = "${cfg.ldapHost}"
    ldap_port = ${toString cfg.ldapPort}

    http_host = "${cfg.httpHost}"
    http_port = ${toString cfg.httpPort}

    http_url = "${cfg.httpUrl}"

    ldap_base_dn = "${cfg.ldapBaseDn}"

    ldap_user_dn = "${cfg.ldapUserDn}"
    ldap_user_email = "${cfg.ldapUserEmail}"

    database_url = "sqlite://${cfg.dataDir}/users.db?mode=rwc"
    key_file = "${cfg.dataDir}/private-key"
  '';
in {
  options.services.lldap = {
    enable = mkEnableOption "lldap";
    ldapHost = mkOption {
      type = types.str;
      default = "0.0.0.0";
      description = "Ldap host address to bind to.";
    };
    ldapPort = mkOption {
      type = types.int;
      default = 3890;
      description = "Ldap port number to bind to.";
    };
    httpHost = mkOption {
      type = types.str;
      default = "0.0.0.0";
      description = "Http web frontend address to bind to.";
    };
    httpPort = mkOption {
      type = types.int;
      default = 17170;
      description = "Http web frontend port number to bind to.";
    };
    httpUrl = mkOption {
      type = types.str;
      default = "https://lldap.example.com";
      description = "The public URL of the server, for password reset links.";
    };
    ldapBaseDn = mkOption {
      type = types.str;
      default = "dc=example,dc=com";
      description = "Base DN for LDAP";
    };
    ldapUserDn = mkOption {
      type = types.str;
      default = "admin";
      description = "Admin username";
    };
    ldapUserEmail = mkOption {
      type = types.str;
      default = "admin@example.com";
      description = "Admin email";
    };
    dataDir = mkOption {
      type = types.path;
      description = "File path containing user pass";
      default = "/var/lib/lldap";
    };
    userPassFile = mkOption {
      type = types.path;
      description = "File path containing user pass";
      default = null;
    };
    jwtSecretFile = mkOption {
      type = types.path;
      description = "File path containing lldap jwt secret";
      default = null;
    };
  };
  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.lldap ];

    systemd.services.lldap = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      preStart = ''
        ln -sf ${pkgs.lldap}/share/lldap ${cfg.dataDir}/app
        ln -sf ${configFile} ${cfg.dataDir}/lldap_config.toml
      '';
      serviceConfig = {
        ExecStart = "${pkgs.lldap}/bin/lldap run";
        LimitNOFILE = 1048576;
        LimitNPROC = 64;
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateTmp = true;
        ProtectHome = true;
        ProtectSystem = "full";
        WorkingDirectory = "${cfg.dataDir}";
        ReadWriteDirectories = "${cfg.dataDir}";
        Restart = "on-failure";
        Type = "simple";
        User = "lldap";
        Group = "lldap";
      };
      environment = {
        LLDAP_JWT_SECRET_FILE = cfg.jwtSecretFile;
        LLDAP_LDAP_USER_PASS_FILE = cfg.userPassFile;
      };
    };

    users.users.lldap = {
      group = "lldap";
      home = "${cfg.dataDir}";
      createHome = true;
      isSystemUser = true;
    };
    users.groups.lldap = { };
  };
}
