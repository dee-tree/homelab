{lib}: {
  client,
  host,
  publicKey,
  serverName,
  port ? 443,
  name ? "safespace",
  fingerprint ? "chrome",
}: let
  encode = value: lib.escapeURL (toString value);

  params = {
    encryption = "none";
    security = "reality";
    type = "tcp";
    sni = serverName;
    fp = fingerprint;
    pbk = publicKey;
    sid = client.sid;
    flow = "xtls-rprx-vision";
    headerType = "none";
    spx = "%2F";
  };

  query = lib.concatStringsSep "&" (
    lib.mapAttrsToList
    (key: value: "${encode key}=${encode value}")
    params
  );
in
  "vless://${client.id}@${host}:${toString port}"
  + "?${query}#${encode name}"
