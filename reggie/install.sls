{%- from 'reggie/map.jinja' import reggie with context -%}

sideboard git latest:
  git.latest:
    - name: https://github.com/magfest/sideboard.git
    - target: {{ reggie.install_dir }}

sideboard configuration:
  file.managed:
    - name: {{ reggie.install_dir }}/development.ini
    - source: salt://reggie/files/sideboard.conf
    - template: jinja
    - require:
      - sideboard git latest

ubersystem git latest:
  git.latest:
    - name: https://github.com/magfest/ubersystem.git
    - target: {{ reggie.install_dir }}/plugins/uber
    - require:
      - sideboard git latest

magprime git latest:
  git.latest:
    - name: https://github.com/magfest/magprime.git
    - target: {{ reggie.install_dir }}/plugins/magprime
    - require:
      - sideboard git latest
