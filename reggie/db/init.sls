{%- from 'reggie/map.jinja' import reggie with context -%}
{%- from 'reggie/dump_ini.jinja' import dump_ini with context -%}

include:
  - reggie.install

postgresql install:
  pkg.installed:
    - pkgs:
      - postgresql
      - postgresql-contrib

reggie db user:
  postgres_user.present:
    - name: {{ reggie.db.username }}
    - password: {{ reggie.db.password }}
    - createdb: False
    - createroles: False
    - createuser: False
    - encrypted: True
    - login: True
    - superuser: False
    - replication: True
    - runas: postgres

reggie db:
  postgres_database.present:
    - name: {{ reggie.db.name }}
    - owner: postgres
    - runas: postgres

reggie db schema migration:
  cmd.run:
    - name: {{ reggie.install_dir }}/env/bin/sep alembic upgrade heads
    - unless: >
        diff
        <({{ reggie.install_dir }}/env/bin/sep alembic current 2> /dev/null | awk '{print $1}' | sort)
        <({{ reggie.install_dir }}/env/bin/sep alembic heads 2> /dev/null | awk '{print $1}' | sort)

reggie db insert test admin:
  cmd.run:
    - name: {{ reggie.install_dir }}/env/bin/sep insert_admin
    - unless: {{ reggie.install_dir }}/env/bin/sep has_admin
