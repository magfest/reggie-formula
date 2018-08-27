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

/home/vagrant/.pythonstartup.py:
  file.managed:
    - name: /home/vagrant/.pythonstartup.py
    - source: salt://reggie/devenv/files/pythonstartup.py
    - user: vagrant
    - group: vagrant
    - template: jinja

{%- for dir in ['/root', '/home/vagrant'] %}
file.managed {{ dir }}/.bash_aliases:
  file.managed:
    - name: {{ dir }}/.bash_aliases

vagrant file.blockreplace {{ dir }}/.bash_aliases:
  file.blockreplace:
    - name: {{ dir }}/.bash_aliases
    - append_if_not_found: True
    - append_newline: True
    - template: jinja
    - require:
      - file: file.managed {{ dir }}/.bash_aliases
    - marker_start: |
        # ==========================================================
        # START BLOCK MANAGED BY SALT (vagrant)
        # ==========================================================
    - content: |
        alias salt-job='salt-run --out highstate jobs.lookup_jid'
    - marker_end: |
        # ==========================================================
        # END BLOCK MANAGED BY SALT (vagrant)
        # ==========================================================
{%- endfor %}

reggie.devenv file.blockreplace /home/vagrant/.bash_aliases:
  file.blockreplace:
    - name: /home/vagrant/.bash_aliases
    - append_if_not_found: True
    - append_newline: True
    - template: jinja
    - require:
      - file: file.managed /home/vagrant/.bash_aliases
    - marker_start: |
        # ==========================================================
        # START BLOCK MANAGED BY SALT (reggie.devenv)
        # ==========================================================
    - source: salt://reggie/devenv/files/bash_aliases
    - marker_end: |
        # ==========================================================
        # END BLOCK MANAGED BY SALT (reggie.devenv)
        # ==========================================================

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
