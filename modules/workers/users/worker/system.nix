{ config, lib, ... }:
let
  ucfg = config.homelab.users.worker;
in
{
  users.users.${ucfg.name}.extraGroups = [ "adm" ]; # for syslogs access

}
