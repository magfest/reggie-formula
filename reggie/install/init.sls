{%- from 'reggie/map.jinja' import reggie with context -%}
{%- from 'reggie/dump_ini.jinja' import dump_ini with context -%}

include:
  - reggie.python

reggie group:
  group.present:
    - name: {{ reggie.group }}

reggie user:
  user.present:
    - name: {{ reggie.user }}

sideboard git latest:
  git.latest:
    - name: https://github.com/magfest/sideboard.git
    - target: {{ reggie.install_dir }}

sideboard configuration:
  file.managed:
    - name: {{ reggie.install_dir }}/development.ini
    - contents: |
        {{ dump_ini(reggie.sideboard.config)|indent(8) }}
    - template: jinja
    - require:
      - sideboard git latest

reggie virtualenv:
  virtualenv.managed:
    - name: {{ reggie.install_dir }}/env
    - python: /usr/bin/python3
    - system_site_packages: False
    - user: {{ reggie.user }}
    - require:
      - python install
      - sideboard git latest

sideboard package install:
  pip.installed:
    - editable: {{ reggie.install_dir }}
    - bin_env: {{ reggie.install_dir }}/env
    - user: {{ reggie.user }}
    - unless: test -f {{ reggie.install_dir }}/env/lib/python3.6/site-packages/sideboard.egg-link
    - require:
      - reggie virtualenv

sideboard requirements update:
  pip.installed:
    - requirements: {{ reggie.install_dir }}/requirements.txt
    - bin_env: {{ reggie.install_dir }}/env
    - user: {{ reggie.user }}
    - require:
      - sideboard package install

{% for plugin_id, plugin in reggie.plugins.items() %}
{{ plugin_id }} git latest:
  git.latest:
    - name: {{ plugin.source }}
    - target: {{ reggie.install_dir }}/plugins/{{ plugin.name }}
    - require:
      - sideboard git latest

{{ plugin_id }} package install:
  pip.installed:
    - editable: {{ reggie.install_dir }}/plugins/{{ plugin.name }}
    - bin_env: {{ reggie.install_dir }}/env
    - user: {{ reggie.user }}
    - unless: test -f {{ reggie.install_dir }}/env/lib/python3.6/site-packages/{{ plugin.name }}.egg-link
    - require:
      - sideboard package install
      - {{ plugin_id }} git latest

{{ plugin_id }} requirements update:
  pip.installed:
    - requirements: {{ reggie.install_dir }}/plugins/{{ plugin.name }}/requirements.txt
    - bin_env: {{ reggie.install_dir }}/env
    - user: {{ reggie.user }}
    - onlyif: grep -q -s '[^[:space:]]' {{ reggie.install_dir }}/plugins/{{ plugin.name }}/requirements.txt
    - require:
      - {{ plugin_id }} package install

{% if plugin.get('config') %}
{{ plugin_id }} configuration:
  file.managed:
    - name: {{ reggie.install_dir }}/plugins/{{ plugin.name }}/development.ini
    - contents: |
        {{ dump_ini(plugin.config)|indent(8) }}
    - template: jinja
    - require:
      - {{ plugin_id }} git latest
{% endif %}
{% endfor %}
