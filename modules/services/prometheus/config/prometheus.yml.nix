{pkgs,...}:
let
yaml = pkgs.formats.yaml {};
in
yaml.generate "prometheus.yml" {
    global = {
      scrape_interval = "30s";
      evaluation_interval = "30s";
      external_labels = {
        monitoring_cluster = "homelab";
        # replica = cfg.replica;
      };
    };
}
