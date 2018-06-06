{%- from 'reggie/map.jinja' import reggie with context -%}
{%- from 'reggie/macros.jinja' import dump_ini with context -%}

include:
  - reggie.python

reggie group:
  group.present:
    - name: {{ reggie.group }}

reggie user:
  user.present:
    - name: {{ reggie.user }}

reggie data_dir:
  file.directory:
    - name: {{ reggie.data_dir }}
    - user: {{ reggie.user }}
    - group: {{ reggie.group }}
    - makedirs: True

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

sideboard git latest:
  git.latest:
    - name: https://github.com/magfest/sideboard.git
    - target: {{ reggie.install_dir }}

chown {{ reggie.user }} {{ reggie.install_dir }}:
  cmd.run:
    - name: chown -R {{ reggie.user }}:{{ reggie.group }} {{ reggie.install_dir }}
    - onlyif: >
        find {{ reggie.install_dir }} -type d \! -user {{ reggie.user }} | grep -q "." &&
        find {{ reggie.install_dir }} -type d \! -group {{ reggie.group }} | grep -q "."
    - require:
      - reggie user
      - reggie group
      - sideboard git latest

reggie virtualenv:
  virtualenv.managed:
    - name: {{ reggie.install_dir }}/env
    - user: {{ reggie.user }}
    - python: /usr/bin/python3
    - system_site_packages: False
    - require:
      - sls: reggie.python
      - chown {{ reggie.user }} {{ reggie.install_dir }}

sideboard configuration:
  file.managed:
    - name: {{ reggie.install_dir }}/development.ini
    - user: {{ reggie.user }}
    - group: {{ reggie.group }}
    - contents: |
        {{ dump_ini(reggie.sideboard.config)|indent(8) }}
    - template: jinja
    - require:
      - reggie virtualenv

sideboard package install:
  pip.installed:
    - editable: {{ reggie.install_dir }}
    - user: {{ reggie.user }}
    - bin_env: {{ reggie.install_dir }}/env
    - unless: test -f {{ reggie.install_dir }}/env/lib/python3.6/site-packages/sideboard.egg-link
    - require:
      - sideboard configuration

sideboard requirements update:
  pip.installed:
    - requirements: {{ reggie.install_dir }}/requirements.txt
    - user: {{ reggie.user }}
    - bin_env: {{ reggie.install_dir }}/env
    - require:
      - sideboard package install

{%- set previous_plugin_ids = ['sideboard'] + reggie.plugins.keys() -%}

{% for plugin_id, plugin in reggie.plugins.items() %}

{{ plugin_id }} git latest:
  git.latest:
    - name: {{ plugin.source }}
    - user: {{ reggie.user }}
    - target: {{ reggie.install_dir }}/plugins/{{ plugin.name }}
    - require:
      - {{ previous_plugin_ids[loop.index0] }} requirements update

{{ plugin_id }} package install:
  pip.installed:
    - editable: {{ reggie.install_dir }}/plugins/{{ plugin.name }}
    - user: {{ reggie.user }}
    - bin_env: {{ reggie.install_dir }}/env
    - unless: test -f {{ reggie.install_dir }}/env/lib/python3.6/site-packages/{{ plugin.name }}.egg-link
    - require:
      - {{ plugin_id }} git latest

{% if plugin.get('config') %}
{{ plugin_id }} configuration:
  file.managed:
    - name: {{ reggie.install_dir }}/plugins/{{ plugin.name }}/development.ini
    - user: {{ reggie.user }}
    - group: {{ reggie.group }}
    - contents: |
        {{ dump_ini(plugin.config)|indent(8) }}
    - template: jinja
    - require:
      - {{ plugin_id }} package install
{% endif %}

{{ plugin_id }} requirements update:
  pip.installed:
    - requirements: {{ reggie.install_dir }}/plugins/{{ plugin.name }}/requirements.txt
    - user: {{ reggie.user }}
    - bin_env: {{ reggie.install_dir }}/env
    - onlyif: grep -q -s '[^[:space:]]' {{ reggie.install_dir }}/plugins/{{ plugin.name }}/requirements.txt
    - require:
      - {{ plugin_id }} package install
{% endfor %}
