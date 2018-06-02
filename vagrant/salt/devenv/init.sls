bash_aliases:
  file.managed:
    - name: /home/vagrant/.bash_aliases
    - contents: |
        alias salt-apply='sudo salt-call --local state.apply'
        export PYTHONSTARTUP='/home/vagrant/.pythonstartup.py'

pythonstartup:
  file.managed:
    - name: /home/vagrant/.pythonstartup.py
    - source: salt://devenv/pythonstartup.py
