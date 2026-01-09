# CrowdSec


## installation

If on ubuntu, add apt repository with:
`curl -s https://install.crowdsec.net | sudo sh`



### traefik bouncer

Enter docker container:
`docker exec -it crowdsec sh`

Generate LAPI key creating the bouncer: 
`cscli bouncers add traefik-bouncer-<hostname>`

### firewall bouncer

In Host OS (outside of docker), install firewall bouncer:

`sudo apt install crowdsec-firewall-bouncer-iptables`
or
`sudo apt install crowdsec-firewall-bouncer-nftables`.
Check if iptables or nftables are used: `iptables -V`.

Enter docker container:
`docker exec -it crowdsec sh`

Generate LAPI key creating the bouncer: 
`cscli bouncers add host-firewall-bouncer-<hostname>`

Modify config file (insert generated LAPI key):
`sudo nvim /etc/crowdsec/bouncers/crowdsec-firewall-bouncer.yaml`