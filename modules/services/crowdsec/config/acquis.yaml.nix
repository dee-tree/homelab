{ lib,...}:
''
filenames:
  - /var/log/traefik/*.log
labels:
  type: traefik
---
filenames:
  - /var/log/auth.log
  - /var/log/syslog
  - /var/log/kern.log
  - /var/log/ufw.log
labels:
  type: syslog
---
listen_addr: 0.0.0.0:7422
appsec_config: crowdsecurity/virtual-patching
name: AppSecComponent
source: appsec
labels:
  type: appsec
''
