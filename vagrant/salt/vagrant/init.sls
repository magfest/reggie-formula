# ============================================================================
# Baseline configuration expected in reggie server.
# ============================================================================

# Make sure rsyslog is installed and running
rsyslog installed and running:
  pkg.installed:
    - name: rsyslog

  service.running:
    - name: rsyslog
    - enable: True
    - require:
      - pkg: rsyslog


# ============================================================================
# Vagrant dev environment
# ============================================================================

{% for file in ['bash_aliases', 'pythonstartup.py'] %}
/home/vagrant/.{{ file }}:
  file.managed:
    - name: /home/vagrant/.{{ file }}
    - source: salt://reggie/devenv/files/{{ file }}
    - user: vagrant
    - group: vagrant
    - template: jinja
{% endfor %}

/etc/salt/minion:
  file.managed:
    - name: /etc/salt/minion
    - source: salt://vagrant/files/salt_minion.conf
