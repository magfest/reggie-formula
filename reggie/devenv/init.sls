# ============================================================================
# Sets up a nice dev environment with a helpful Python REPL and bash aliases.
# ============================================================================

reggie /root/.pythonstartup.py:
  file.managed:
    - name: /root/.pythonstartup.py
    - source: salt://reggie/devenv/files/pythonstartup.py
    - template: jinja

reggie file.managed /root/.bash_aliases:
  file.managed:
    - name: /root/.bash_aliases
    - replace: False

reggie file.blockreplace /root/.bash_aliases:
  file.blockreplace:
    - name: /root/.bash_aliases
    - append_if_not_found: True
    - append_newline: True
    - template: jinja
    - require:
      - file: reggie file.managed /root/.bash_aliases
    - marker_start: '# ==== START BLOCK MANAGED BY SALT (reggie.devenv) ===='
    - source: salt://reggie/devenv/files/bash_aliases
    - marker_end: '# ==== END BLOCK MANAGED BY SALT (reggie.devenv) ===='
