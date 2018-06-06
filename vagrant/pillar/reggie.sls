reggie:
  user: vagrant
  group: vagrant
  install_dir: /home/vagrant/reggie-formula/reggie-deploy
  data_dir: /home/vagrant/.reggie/data

  plugins:
    magprime:
      name: magprime
      source: https://github.com/magfest/magprime.git

postgres:
  use_upstream_repo: False
  pkgs_extra:
    - postgresql-contrib
  manage_force_reload_modules: False

rabbitmq:
  enabled: True
  running: True
  vhost:
    vh_name: reggie
  user:
    reggie:
      - password: reggie
      - tags:
        - monitoring
        - user
      - perms:
        - reggie:
          - '.*'
          - '.*'
          - '.*'
      - runas: root
  queues:
    name: reggie
    vhost: reggie
    durable: True
    auto_delete: False

redis:
  pass: reggie
  port: 6379
  bind: 127.0.0.1
