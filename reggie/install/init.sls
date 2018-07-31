# ============================================================================
# Installs the reggie source code and creates a Python virtual environment
# ============================================================================

{%- from 'reggie/map.jinja' import reggie with context %}
{%- from 'reggie/macros.jinja' import dump_ini with context %}
{%- set env = salt['grains.get']('env') %}

include:
  - reggie.python

# Create the reggie user and group
reggie user:
  group.present:
    - name: {{ reggie.group }}
  user.present:
    - gid: {{ reggie.group }}
    - name: {{ reggie.user }}

reggie service:
  file.managed:
    - name: /lib/systemd/system/reggie.service
    - contents: |
        [Unit]
        Description=Reggie services collection

        [Service]
        Type=oneshot
        ExecStart=/bin/true
        RemainAfterExit=yes

        [Install]
        WantedBy=multi-user.target
    - template: jinja

reggie sideboard git latest:
  git.latest:
    - name: https://github.com/magfest/sideboard.git
    - target: {{ reggie.install_dir }}

reggie chown {{ reggie.user }} {{ reggie.install_dir }}:
  cmd.run:
    - name: chown -R {{ reggie.user }}:{{ reggie.group }} {{ reggie.install_dir }}
    - onlyif: >
        find {{ reggie.install_dir }} -type d \! -user {{ reggie.user }} | grep -q "." &&
        find {{ reggie.install_dir }} -type d \! -group {{ reggie.group }} | grep -q "."
    - require:
      - reggie user
      - reggie sideboard git latest

{%- for dir in ['mounted_data_dir', 'data_dir'] %}
reggie chown {{ reggie.user }} {{ reggie.plugins.ubersystem.config[dir] }}:
  file.directory:
    - name: {{ reggie.plugins.ubersystem.config[dir] }}
    - user: {{ reggie.user }}
    - group: {{ reggie.group }}
    - makedirs: True
    - recurse:
      - user
      - group
    - require:
      - reggie user
      - reggie sideboard git latest
{%- endfor %}

reggie virtualenv:
  virtualenv.managed:
    - name: {{ reggie.install_dir }}/env
    - user: {{ reggie.user }}
    - python: /usr/bin/python3
    - system_site_packages: False
    - require:
      - sls: reggie.python
      - reggie chown {{ reggie.user }} {{ reggie.install_dir }}

reggie sideboard configuration:
  file.managed:
    - name: {{ reggie.install_dir }}/development.ini
    - user: {{ reggie.user }}
    - group: {{ reggie.group }}
    - contents: |
        {{ dump_ini(reggie.sideboard.config)|indent(8) }}
    - template: jinja
    - show_changes: {% if env == 'dev' %}True{% else %}False{% endif %}
    - require:
      - reggie virtualenv

reggie sideboard package install:
  pip.installed:
    - editable: {{ reggie.install_dir }}
    - user: {{ reggie.user }}
    - bin_env: {{ reggie.install_dir }}/env
    - unless: test -f {{ reggie.install_dir }}/env/lib/python3.6/site-packages/sideboard.egg-link
    - require:
      - reggie sideboard configuration

reggie sideboard requirements update:
  pip.installed:
    - requirements: {{ reggie.install_dir }}/requirements.txt
    - user: {{ reggie.user }}
    - bin_env: {{ reggie.install_dir }}/env
    - require:
      - reggie sideboard package install

{%- set previous_plugin_ids = ['sideboard'] + reggie.plugins.keys() -%}

{% for plugin_id, plugin in reggie.plugins.items() %}

reggie {{ plugin_id }} git latest:
  git.latest:
    - name: {{ plugin.source }}
    - user: {{ reggie.user }}
    - target: {{ reggie.install_dir }}/plugins/{{ plugin.name }}
    - require:
      - reggie {{ previous_plugin_ids[loop.index0] }} requirements update

reggie {{ plugin_id }} package install:
  pip.installed:
    - editable: {{ reggie.install_dir }}/plugins/{{ plugin.name }}
    - user: {{ reggie.user }}
    - bin_env: {{ reggie.install_dir }}/env
    - unless: test -f {{ reggie.install_dir }}/env/lib/python3.6/site-packages/{{ plugin.name }}.egg-link
    - require:
      - reggie {{ plugin_id }} git latest

{% if plugin.get('config') %}
reggie {{ plugin_id }} configuration:
  file.managed:
    - name: {{ reggie.install_dir }}/plugins/{{ plugin.name }}/development.ini
    - user: {{ reggie.user }}
    - group: {{ reggie.group }}
    - contents: |
        {{ dump_ini(plugin.config)|indent(8) }}
    - template: jinja
    - show_changes: {% if env == 'dev' %}True{% else %}False{% endif %}
    - require:
      - reggie {{ plugin_id }} package install
{% endif %}

reggie {{ plugin_id }} requirements update:
  pip.installed:
    - requirements: {{ reggie.install_dir }}/plugins/{{ plugin.name }}/requirements.txt
    - user: {{ reggie.user }}
    - bin_env: {{ reggie.install_dir }}/env
    - onlyif: grep -q -s '[^[:space:]]' {{ reggie.install_dir }}/plugins/{{ plugin.name }}/requirements.txt
    - require:
      - reggie {{ plugin_id }} package install
{% endfor %}
