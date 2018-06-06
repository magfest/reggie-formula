/root/.bash_aliases:
  file.managed:
    - name: /root/.bash_aliases
    - source: salt://reggie/devenv/files/bash_aliases
    - template: jinja

/root/.pythonstartup.py:
  file.managed:
    - name: /root/.pythonstartup.py
    - source: salt://reggie/devenv/files/pythonstartup.py
