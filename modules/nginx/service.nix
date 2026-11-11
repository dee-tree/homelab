# home-manager service
{
  httpPort ? 80,
  httpsPorts ? 443,
  ...
}:
{ pkgs, ... }: # arguments are supplied by home-manager
{
  services.podman = {
    enable = true;

    containers.nginx = {
      # image = "docker.io/library/nginx:stable-alpine";
      image = "public.ecr.aws/docker/library/nginx:stable-alpine";
      # ports = [ "127.0.0.1:${toString httpPort}:80" "127.0.0.1:${toString httpsPort}:443" ];
      ports = [ "127.0.0.1:8080:80" ];
      autoStart = true;
    };
  };

}
