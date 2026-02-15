{
  lib,
  pkgs,
  config,
  ...
}:
let
  compressionConf = ''
    gzip "on";
    gzip_types  "text/plain" "text/html" "application/json" "application/xml" "application/wasm";
    gzip_min_length 256;
  '';
in
{
  options.cinny.enable = lib.mkEnableOption "Cinny";

  config = lib.mkIf config.cinny.enable {
    services.nginx.virtualHosts."cinny.${config.domain}" = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        root = toString pkgs.cinny;
        extraConfig = ''
          etag on;
          rewrite ^/config.json$ /config.json break;
          rewrite ^/manifest.json$ /manifest.json break;
          rewrite ^/sw.js$ /sw.js break;
          rewrite ^/pdf.worker.min.js$ /pdf.worker.min.js break;
          rewrite ^/public/(.*)$ /public/$1 break;
          rewrite ^/assets/(.*)$ /assets/$1 break;
          rewrite ^(.+)$ /index.html break;
          ${compressionConf}
        '';
      };
    };
  };
}
