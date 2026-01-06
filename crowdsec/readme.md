# CrowdSec


## installation

If on ubuntu, add apt repository with:
`curl -s https://install.crowdsec.net | sudo sh`

In Host OS (outside of docker), install firewall bouncer:

`sudo apt install crowdsec-firewall-bouncer-iptables`
or
`sudo apt install crowdsec-firewall-bouncer-nftables`.
Check if iptables or nftables are used: `iptables -V`.


