let
  mkServiceUser = import ../mk-service-user.nix;
in
mkServiceUser {
  user = "worker-nginx";
  uid = 801;
  subIdStart = 200000;
  homeModule = {
    imports = [
      (import ./service.nix { })
    ];
  };
}
