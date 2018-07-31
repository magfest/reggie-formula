{%- set certs_dir = salt['pillar.get']('ssl:certs_dir') %}

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
# Install vagrant development certs
# NEVER USE THESE FOR PRODUCTION
# ============================================================================

{% for file in ['vagrant.crt', 'vagrant.key', 'vagrant.pem'] %}
{{ certs_dir }}/{{ file }}:
  file.managed:
    - name: {{ certs_dir }}/{{ file }}
    - source: salt://vagrant/files/{{ file }}
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
    - source: salt://vagrant/files/salt_minion.conf
