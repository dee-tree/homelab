{
  image = "docker.io/library/nginx";
  # image = "public.ecr.aws/docker/library/nginx";
  label = import ./version.nix;

  ip4 = "10.90.0.10";
}
