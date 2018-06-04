{%- from 'reggie/map.jinja' import reggie with context -%}

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
    - name: {{ reggie.db.database }}
    - owner: postgres
    - runas: postgres
