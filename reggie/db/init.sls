# ============================================================================
# Creates the reggie database and runs any needed database migrations.
# ============================================================================

{%- from 'reggie/map.jinja' import reggie with context %}

include:
  - reggie.install

# Create the reggie database and user
reggie db:
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
  postgres_database.present:
    - name: {{ reggie.db.name }}
    - owner: postgres
    - runas: postgres

# Run any schema migrations if needed
reggie db schema migrations:
  cmd.run:
    - name: {{ reggie.install_dir }}/env/bin/sep alembic upgrade heads
    - unless: >
        diff
        <({{ reggie.install_dir }}/env/bin/sep alembic current 2> /dev/null | awk '{print $1}' | sort)
        <({{ reggie.install_dir }}/env/bin/sep alembic heads 2> /dev/null | awk '{print $1}' | sort)

# Insert the Test Developer <magfest@example.com> account. This will only run
# on new installations that don't have any admin accounts yet.
reggie db insert test admin:
  cmd.run:
    - name: {{ reggie.install_dir }}/env/bin/sep insert_admin
    - unless: >
        su postgres -c
        "psql -q -t -c \"select 'yes' as has_admin from admin_account limit 1;\" {{ reggie.db.name }}"
        2> /dev/null |
        grep -q 'yes'
