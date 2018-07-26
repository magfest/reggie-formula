{%- set ssl_dir = '/etc/ssl' -%}
{%- set certs_dir = ssl_dir ~ '/certs' -%}
{%- set private_ip = salt['network.interface_ip']('eth0') -%}


{%- macro nginx_ssl_config(key, cert, dhparam) -%}

- ssi: 'on'
- ssl: 'on'
- ssl_session_cache: shared:SSL:10m
- ssl_session_timeout: 10m

- ssl_certificate_key: {{ key }}
- ssl_certificate: {{ cert }}
- ssl_protocols: TLSv1 TLSv1.1 TLSv1.2

- ssl_ciphers: 'ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES256-SHA:ECDHE-ECDSA-DES-CBC3-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA:!DSS'
- ssl_prefer_server_ciphers: 'on'
- ssl_dhparam: {{ dhparam }}
{%- endmacro -%}


{%- macro nginx_proxy_config(from_port, front_end_https=False) -%}

- client_max_body_size: 20m
- client_body_buffer_size: 20m

- proxy_connect_timeout: 90
- proxy_send_timeout: 90
- proxy_read_timeout: 90
- send_timeout: 90
- proxy_buffering: 'off'

- proxy_http_version: 1.1
- proxy_set_header: Host $host{%- if front_end_https %}:{{ from_port }}{%- endif %}
- proxy_set_header: X-Real-IP $remote_addr
- proxy_set_header: X-Forwarded-For $proxy_add_x_forwarded_for
- proxy_set_header: X-Forwarded-Proto $scheme
- proxy_set_header: X-Forwarded-Host $host{%- if front_end_https %}:{{ from_port }}{%- endif %}
- proxy_set_header: X-Forwarded-Server $host
- proxy_set_header: X-Forwarded-Port $server_port
{%- if front_end_https %}
- add_header: Front-End-Https 'on'
{%- endif %}
{%- endmacro -%}


ssl:
  dir: {{ ssl_dir }}
  certs_dir: {{ certs_dir }}


reggie:
  user: vagrant
  group: vagrant
  install_dir: /home/vagrant/reggie-formula/reggie-deploy

  plugins:
    magprime:
      name: magprime
      source: https://github.com/magfest/magprime.git

    ubersystem:
      config:
        data_dir: /home/vagrant/reggie_data
        mounted_data_dir: /home/vagrant/reggie_data/mnt


glusterfs:
  server:
    enabled: True
    service: glusterd
    peers:
      - {{ private_ip }}
    volumes:
      reggie_volume:
        storage: /srv/data/glusterfs/reggie_volume
        bricks:
          - {{ private_ip }}:/srv/data/glusterfs/reggie_volume
  client:
    enabled: True
    volumes:
      reggie_volume:
        path: /home/vagrant/reggie_data/mnt
        server: {{ private_ip }}
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
      reggie_load_balancer:
        mode: http

        binds:
        - address: 0.0.0.0
          port: 8888

        servers:
        - name: reggie_backend
          host: 127.0.0.1
          port: 443
          params: ssl verify none


nginx:
  ng:
    certificates_path: {{ certs_dir }}
    dh_param:
      dhparams.pem:
        keysize: 2048
    service:
      enable: True
    server:
      config:
        user: www-data
        worker_processes: auto
        worker_rlimit_nofile: 20000
        pid: /run/nginx.pid

        events:
          worker_connections: 1024

        http:
          sendfile: 'on'
          tcp_nopush: 'on'
          tcp_nodelay: 'on'
          keepalive_timeout: 65
          types_hash_max_size: 2048
          server_tokens: 'off'
          server_names_hash_bucket_size: 128
          variables_hash_bucket_size: 128
          default_type: application/octet-stream

          access_log: /var/log/nginx/access.log
          error_log: /var/log/nginx/error.log

          gzip: 'on'
          gzip_disable: '"msie6"'
          include:
            - /etc/nginx/mime.types
            - /etc/nginx/conf.d/*.conf
            - /etc/nginx/sites-enabled/*

    servers:
      managed:
        default:
          enabled: False
          config: []

        reggie_external_http_to_https:
          enabled: True
          overwrite: True
          config:
            - server:
              - server_name: localhost
              - listen: 8000
              - return: '301 https://localhost:4443$request_uri'

        reggie_external_https_to_loadbalancer:
          enabled: True
          overwrite: True
          config:
            - server:
              - server_name: localhost
              - listen: 4443
              {{ nginx_ssl_config(certs_dir ~ '/localhost.key', certs_dir ~ '/localhost.crt', certs_dir ~ '/dhparams.pem')|indent(14) }}

              - 'location ~ ^/(reggie|uber)(/.*)?$':
                - return: '302 https://localhost:4443$2'

              - 'location /':
                - rewrite: '/(.*) /reggie/$1 break'
                - proxy_pass: 'http://localhost:8888'
                - proxy_redirect: 'https://localhost/reggie https://localhost:4443'
                {{ nginx_proxy_config(4443, True)|indent(16) }}
                - 'if (-f $document_root/maintenance.html)':
                  - return: 503

        reggie_internal_https_site:
          enabled: True
          overwrite: True
          config:
            - server:
              - server_name: localhost
              - listen: 443
              {{ nginx_ssl_config(certs_dir ~ '/localhost.key', certs_dir ~ '/localhost.crt', certs_dir ~ '/dhparams.pem')|indent(14) }}
              - location /:
                - proxy_pass: 'http://localhost:8282'
                - proxy_redirect: 'http:// https://'
                {{ nginx_proxy_config(443)|indent(16) }}


postgres:
  use_upstream_repo: False
  pkgs_extra: [postgresql-contrib]
  manage_force_reload_modules: False
  postgresconf: listen_addresses = 'localhost,{{ private_ip }}'

  cluster:
    locale: en_US.UTF-8

  acls:
    - ['local', 'all', 'all']
    - ['host', 'all', 'all', '127.0.0.1/32', 'md5']
    - ['hostssl', 'all', 'all', '{{ private_ip }}/24', 'md5']

  users:
    reggie:
      ensure: present
      password: reggie
      createdb: False
      createroles: False
      encrypted: True
      login: True
      superuser: False
      replication: True
      runas: postgres

  databases:
    reggie:
      runas: postgres
      template: template0
      encoding: UTF8
      lc_ctype: en_US.UTF-8
      lc_collate: en_US.UTF-8


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
