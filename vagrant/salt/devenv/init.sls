{%- from 'reggie/map.jinja' import reggie with context -%}

bash_aliases:
  file.managed:
    - name: /home/vagrant/.bash_aliases
    - contents: |
        export PYTHONSTARTUP='/home/vagrant/.pythonstartup.py'
        export PATH="{{ reggie.install_dir }}/env/bin:$PATH"
        alias salt-local='sudo salt-call --local'
        alias salt-apply='sudo salt-call --local state.apply'
        alias run_server='{{ reggie.install_dir }}/env/bin/python {{ reggie.install_dir }}/run_server.py'
        source {{ reggie.install_dir }}/env/bin/activate

pythonstartup:
  file.managed:
    - name: /home/vagrant/.pythonstartup.py
    - source: salt://devenv/pythonstartup.py
