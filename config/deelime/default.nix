{
  services = {
    nginx = import ../modules/nginx;
    xray = import ../modules/xray;
    traefik = import ../modules/traefik;
    crowdsec = import ../modules/crowdsec;
  };
}
