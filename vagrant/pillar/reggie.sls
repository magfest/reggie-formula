reggie:
  user: vagrant
  group: vagrant
  install_dir: /home/vagrant/reggie-formula/reggie-deploy
  data_dir: /home/vagrant/.reggie/data

  plugins:
    magprime:
      name: magprime
      source: https://github.com/magfest/magprime.git


nginx:
  server:
    enabled: True
    bind:
      address: '0.0.0.0'
      ports:
      - 8000
      - 4443
    site:
      http_to_https:
        enabled: True
        type: nginx_redirect
        name: http_to_https
        host:
          name: localhost
          port: 8000
        redirect:
          protocol: https
          host: localhost:4443  # Need the port to redirect correctly
      https_reggie_site:
        enabled: True
        type: nginx_proxy
        name: https_reggie_site
        proxy:
          host: localhost
          port: 8282
          protocol: http
        ssl:
          enabled: True
          # engine: letsencrypt
          cert_file: /etc/ssl/certs/localhost.crt
          key_file: /etc/ssl/certs/localhost.key
        host:
          name: localhost
          port: 4443


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
