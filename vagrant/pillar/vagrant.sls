{%- set certs_dir = '/etc/ssl/certs' -%}
{%- set ip_addr = salt['network.interface_ip']('eth0') -%}

ssl:
  dir: /etc/ssl
  certs_dir: {{ certs_dir }}


reggie:
  user: vagrant
  group: vagrant
  install_dir: /home/vagrant/reggie-formula/reggie-deploy
  data_dir: /home/vagrant/reggie_data
  uploaded_files_dir: /home/vagrant/reggie_data/uploaded_files

  plugins:
    magprime:
      name: magprime
      source: https://github.com/magfest/magprime.git


glusterfs:
  server:
    enabled: True
    service: glusterd
    peers:
      - {{ ip_addr }}
    volumes:
      reggie_volume:
        storage: /srv/data/glusterfs/reggie_volume
        bricks:
          - {{ ip_addr }}:/srv/data/glusterfs/reggie_volume
  client:
    enabled: True
    volumes:
      reggie_volume:
        path: /home/vagrant/reggie_data/uploaded_files
        server: {{ ip_addr }}
        user: vagrant
        group: vagrant


haproxy:
  proxy:
    enabled: True
    mode: http
    logging: syslog
    maxconn: 1024
    timeout:
      connect: 5000
      client: 50000
      server: 50000
    listen:
      reggie_http_to_https_redirect:
        mode: http

        http_request:
          - action: 'redirect location https://%H:4443%HU code 301'

        binds:
        - address: 0.0.0.0
          port: 8000

      reggie_load_balancer:
        mode: http
        force_ssl: True

        acl:
          header_location_exists: 'res.hdr(Location) -m found'
          path_starts_with_app: 'path_beg -i /app'
          path_starts_with_profiler: 'path_beg -i /profiler'

        http_response:
          - action: 'replace-value Location https://([^/]*)(?:/app)?(.*) https://\1:4443\2'
            condition: 'if header_location_exists'

        http_request:
          - action: 'set-path /app/%[path]'
            condition: 'if !path_starts_with_app !path_starts_with_profiler'

        binds:
        - address: 0.0.0.0
          port: 4443
          ssl:
            enabled: True
            pem_file: {{ certs_dir }}/localhost.pem

        servers:
        - name: reggie_backend
          host: 127.0.0.1
          port: 443
          params: ssl verify none


nginx:
  server:
    enabled: True
    bind:
      address: '0.0.0.0'
      ports:
      - 80
      - 443
    site:
      http_to_https:
        enabled: True
        type: nginx_redirect
        name: http_to_https
        host:
          name: localhost
          port: 80
        redirect:
          protocol: https
          host: localhost  #:4443 Need to include port if using non-standard https port
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
          cert_file: {{ certs_dir }}/localhost.crt
          key_file: {{ certs_dir }}/localhost.key
        host:
          name: localhost
          port: 443


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
