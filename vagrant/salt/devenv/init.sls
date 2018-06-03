bash_aliases:
  file.managed:
    - name: /home/vagrant/.bash_aliases
    - contents: |
        export PYTHONSTARTUP='/home/vagrant/.pythonstartup.py'
        export PATH="/home/vagrant/reggie-formula/reggie-deploy/env/bin:$PATH"
        alias salt-local='sudo salt-call --local'
        alias salt-apply='sudo salt-call --local state.apply'
        alias run_server='/home/vagrant/reggie-formula/reggie-deploy/env/bin/python /home/vagrant/reggie-formula/reggie-deploy/run_server.py'
        source /home/vagrant/reggie-formula/reggie-deploy/env/bin/activate

pythonstartup:
  file.managed:
    - name: /home/vagrant/.pythonstartup.py
    - source: salt://devenv/pythonstartup.py
