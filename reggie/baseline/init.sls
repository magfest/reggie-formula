rsyslog install:
  pkg.installed:
    - name: rsyslog

rsyslog:
  service.running:
    - name: rsyslog
    - enable: True
    - require:
      - pkg: rsyslog

update-locale LANG="en_US.UTF-8":
  cmd.run:
    - name: update-locale LANG="en_US.UTF-8"
    - unless: grep -q -E "LANG=[\"']?en_US.UTF-8[\"']?" /etc/default/locale
