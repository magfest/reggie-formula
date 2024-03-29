# ============================================================================
# Installs the reggie source code and creates a Python virtual environment
# ============================================================================

{%- from 'reggie/map.jinja' import reggie with context %}
{%- from 'reggie/macros.jinja' import dump_ini, handle_windows_permissions with context %}
{%- set env = salt['grains.get']('env') %}


# Install the python dependencies
reggie pip install:
  pkg.installed:
    - name: python-pip
    - reload_modules: True

reggie python install:
  pkg.installed:
    - reload_modules: True
    - pkgs:
      - python
      - python-pip
      - python3
      - python3-pip
      - python3-tk
      - virtualenv
      - libpq-dev        # for psycopg
      - build-essential  # for python-prctl
      - libcap-dev       # for python-prctl
      - libjpeg-dev      # for treepoem
      - ghostscript      # for treepoem

  pip.installed:
    - name: virtualenv
    - bin_env: /usr/bin/pip3


# Create the reggie user and group
reggie user:
  group.present:
    - name: {{ reggie.group }}
    - order: first
  user.present:
    - gid: {{ reggie.group }}
    - name: {{ reggie.user }}
    - order: first
    - require:
      - group: {{ reggie.group }}

reggie.service:
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

  service.enabled:
    - name: reggie
    - require:
      - file: reggie.service
    - watch_any:
      - file: reggie.service

set root home envvar:
  environ.setenv:
    - name: HOME
    - value: '/root'
    - update_minion: True

set git safe directory for reggie install dir:
  git.config_set:
    - name: safe.directory
    - value: {{ reggie.install_dir }}
    - global: True

reggie sideboard git latest:
  git.latest:
    - name: https://github.com/magfest/sideboard.git
    - target: {{ reggie.install_dir }}
    - rev: {{ reggie.sideboard.branch if reggie.sideboard.get('branch') else 'master' }}
    - branch: {{ reggie.sideboard.branch if reggie.sideboard.get('branch') else 'master' }}
    - remote: origin

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
reggie chown {{ reggie.user }} {{ reggie[dir] }}:
  file.directory:
    - name: {{ reggie[dir] }}
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

# note: if running on windows+vagrant, virtualbox's shared win host -> linux vm FS implementation
# doesn't support symlinks so we need to use VIRTUALENV_ALWAYS_COPY which causes file copies instead of symlinks
reggie virtualenv:
  virtualenv.managed:
    - name: {{ reggie.install_dir }}/env
    - user: {{ reggie.user }}
    - python: /usr/bin/python3
    - venv_bin: /usr/bin/virtualenv
    - system_site_packages: False
    {% if grains.get('is_vagrant_windows', false) %}
    - env:
      - VIRTUALENV_ALWAYS_COPY: 1
    {% endif %}
    - require:
      - pip: virtualenv
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
    {{ handle_windows_permissions() }}
    - require:
      - reggie virtualenv

reggie setuptools downgrade:
  pip.installed:
    - pkgs:
      - setuptools==57.0.0
    - user: {{ reggie.user }}
    - bin_env: {{ reggie.install_dir }}/env/bin/pip
    - require:
      - reggie sideboard configuration
      
reggie sideboard package install:
  pip.installed:
    - editable: file://{{ reggie.install_dir }}
    - user: {{ reggie.user }}
    - bin_env: {{ reggie.install_dir }}/env/bin/pip
    - unless: test -f {{ reggie.install_dir }}/env/lib/python3.6/site-packages/sideboard.egg-link
    - require:
      - reggie setuptools downgrade

reggie sideboard requirements update:
  pip.installed:
    - requirements: {{ reggie.install_dir }}/requirements.txt
    - user: {{ reggie.user }}
    - bin_env: {{ reggie.install_dir }}/env/bin/pip
    - require:
      - reggie sideboard package install

{%- set previous_plugin_ids = ['sideboard'] + reggie.plugins.keys() | list -%}

{% for plugin_id, plugin in reggie.plugins.items() %}

reggie {{ plugin_id }} git latest:
  git.latest:
    - name: {{ plugin.source }}
    - user: {{ reggie.user }}
    - target: {{ reggie.install_dir }}/plugins/{{ plugin.name }}
    - rev: {{ plugin.branch if plugin.get('branch') else 'master' }}
    - branch: {{ plugin.branch if plugin.get('branch') else 'master' }}
    - remote: origin
    - require:
      - reggie {{ previous_plugin_ids[loop.index0] }} requirements update

reggie {{ plugin_id }} package install:
  pip.installed:
    - editable: {{ reggie.install_dir }}/plugins/{{ plugin.name }}
    - user: {{ reggie.user }}
    - bin_env: {{ reggie.install_dir }}/env/bin/pip
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
    {{ handle_windows_permissions() }}
    - require:
      - reggie {{ plugin_id }} package install
{% endif %}

reggie {{ plugin_id }} requirements update:
  pip.installed:
    - requirements: {{ reggie.install_dir }}/plugins/{{ plugin.name }}/requirements.txt
    - user: {{ reggie.user }}
    - bin_env: {{ reggie.install_dir }}/env/bin/pip
    - onlyif: grep -q -s '[^[:space:]]' {{ reggie.install_dir }}/plugins/{{ plugin.name }}/requirements.txt
    - require:
      - reggie {{ plugin_id }} package install
{% endfor %}

{% for path, contents in reggie.extra_files.items() %}
{% set absolute_path = path if path.startswith('/') else reggie.install_dir ~ '/' ~ path %}
{% set file_spec = {'contents': contents} if contents is string else contents %}
{{ absolute_path }}:
  file.managed:
    - name: {{ absolute_path }}
    - user: {{ reggie.user }}
    - group: {{ reggie.group }}
    {{ handle_windows_permissions() }}
    {% for key, value in file_spec.items() %}
    {% if key == 'contents' %}
    - contents: |
        {{ value|indent(8) }}
    {% else %}
    - {{ key }}: {{ value }}
    {% endif %}
    {% endfor %}
{% endfor %}
