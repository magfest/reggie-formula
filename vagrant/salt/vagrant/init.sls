# ============================================================================
# Vagrant dev environment
# ============================================================================

/home/vagrant/.bash_aliases:
  file.managed:
    - name: /home/vagrant/.bash_aliases
    - source: salt://reggie/devenv/files/bash_aliases
    - template: jinja

/home/vagrant/.pythonstartup:
  file.managed:
    - name: /home/vagrant/.pythonstartup.py
    - source: salt://reggie/devenv/files/pythonstartup.py

/etc/salt/minion:
  file.managed:
    - name: /etc/salt/minion
    - source: salt://vagrant/salt_minion.conf
