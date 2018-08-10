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

{% for file in ['master', 'minion'] %}
/etc/salt/{{ file }}:
  file.managed:
    - name: /etc/salt/{{ file }}
    - source: salt://vagrant/files/salt_{{ file }}.yaml

  service.running:
    - name: salt-{{ file }}
    - enable: True
    - order: last
    - watch:
      - file: /etc/salt/{{ file }}
{% endfor %}
