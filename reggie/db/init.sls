# ============================================================================
# Runs any needed database migrations and creates test admin if needed.
# This state assumes the database and user already exist.
# ============================================================================

{%- from 'reggie/map.jinja' import reggie with context %}

include:
  - reggie.install

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
    - unless: {{ reggie.install_dir }}/env/bin/sep has_admin
