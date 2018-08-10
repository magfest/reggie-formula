{%- set certs_dir = salt['pillar.get']('ssl:certs_dir') %}

saltutil.sync_all:
  module.run:
    - saltutil.sync_all

saltutil.refresh_pillar:
  module.run:
    - saltutil.refresh_pillar: []

mine.update:
  module.run:
    - saltutil.refresh_pillar: []
    - reload_modules: True


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
# Install reggie development certs
# NEVER USE THESE FOR PRODUCTION
# ============================================================================

{% for ext in ['crt', 'key', 'pem'] %}
{{ certs_dir }}/reggie.{{ ext }}:
  file.managed:
    - name: {{ certs_dir }}/reggie.{{ ext }}
    - source: salt://vagrant/files/ssl.{{ ext }}
    - user: vagrant
    - group: vagrant
{% endfor %}


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
    - source: salt://vagrant/files/salt_minion.yaml
