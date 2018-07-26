{%- from 'nginx_macros.jinja' import nginx_ssl_config, nginx_proxy_config -%}
{%- set minion_id = salt['grains.get']('id') %}
{%- set ssl_dir = '/etc/ssl' -%}
{%- set certs_dir = ssl_dir ~ '/certs' -%}
{%- set private_ip = salt['network.interface_ip']('eth0') -%}

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
          {%- for header in ['Location', 'Refresh'] %}
          header_{{ header|lower }}_exists: 'res.hdr({{ header }}) -m found'
          {%- endfor %}

          {%- for path in ['reggie', 'uber', 'profiler', 'stats'] %}
          path_is_{{ path }}: 'path -i /{{ path }}'
          path_starts_with_{{ path }}: 'path_beg -i /{{ path }}/'
          {%- endfor %}

        http_response:
          {%- for header in ['Location', 'Refresh'] %}
          - action: 'replace-value {{ header }} https://([^/]*)(?:/reggie)?(.*) https://\1:4443\2'
            condition: 'if header_{{ header|lower }}_exists'
          {%- endfor %}

        http_request:
          {%- for path in ['reggie', 'uber'] %}
          - action: 'redirect location https://%[hdr(host)]%[url,regsub(^/{{ path }}/?,/,i)] code 302'
            condition: 'if path_is_{{ path }} path_starts_with_{{ path }}'
          {%- endfor %}
          - action: 'set-path /reggie%[path]'
            condition: 'if !path_is_profiler !path_starts_with_profiler !path_is_stats !path_starts_with_stats'

        binds:
        - address: 0.0.0.0
          port: 4443
          ssl:
            enabled: True
            pem_file: {{ certs_dir }}/{{ minion_id }}.pem

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
        worker_processes: auto
        worker_rlimit_nofile: 20000

        events:
          worker_connections: 1024

        http:
          client_body_buffer_size: 128k
          client_max_body_size: 20m
          gzip: 'on'
          gzip_min_length: 10240
          gzip_proxied: expired no-cache no-store private auth
          gzip_types: text/plain text/css text/xml text/javascript application/x-javascript application/json application/xml
          reset_timedout_connection: 'on'
          proxy_cache_path: '/var/cache/nginx levels=1:2 keys_zone=one:8m max_size=3000m inactive=600m'
          server_tokens: 'off'
          include:
            - /etc/nginx/mime.types
            - /etc/nginx/conf.d/*.conf
            - /etc/nginx/sites-enabled/*

    servers:
      managed:
        default:
          enabled: False
          config: []

        reggie_site:
          enabled: True
          overwrite: True
          config:
            - server:
              - server_name: localhost
              - listen: 443
              {{ nginx_ssl_config(
                  certs_dir ~ '/localhost.key',
                  certs_dir ~ '/localhost.crt',
                  certs_dir ~ '/dhparams.pem')|indent(14) }}

              {%- for location in ['/preregistration/form'] %}
              - 'location = /reggie{{ location }}':
                - proxy_hide_header: Cache-Control
                {{ nginx_proxy_config(443, cache='/etc/nginx/reggie_short_term_cache.conf')|indent(16) }}
              {%- endfor %}

              {%- for location in ['/static/', '/static_views/'] %}
              - 'location /reggie{{ location }}':
                {{ nginx_proxy_config(443, cache='/etc/nginx/reggie_long_term_cache.conf')|indent(16) }}
              {%- endfor %}

              - 'location /':
                {{ nginx_proxy_config(443)|indent(16) }}

        reggie_long_term_cache.conf:
          enabled: True
          available_dir: /etc/nginx
          enabled_dir: /etc/nginx
          config:
            - proxy_cache: one
            - proxy_cache_key: $host$request_uri|$request_body
            - proxy_cache_valid: 200 60m
            - proxy_cache_use_stale: error timeout invalid_header updating http_500 http_502 http_503 http_504
            - proxy_cache_bypass: $http_secret_header $arg_nocache
            - add_header: X-Cache-Status $upstream_cache_status

        reggie_short_term_cache.conf:
          enabled: True
          available_dir: /etc/nginx
          enabled_dir: /etc/nginx
          config:
            - proxy_cache: one
            - proxy_cache_key: $host$request_uri
            - proxy_cache_valid: 200 20s
            - proxy_cache_lock: 'on'
            - proxy_cache_lock_age: 40s
            - proxy_cache_lock_timeout: 40s
            - proxy_cache_use_stale: error timeout invalid_header updating http_500 http_502 http_503 http_504
            - proxy_cache_bypass: $http_secret_header $cookie_nocache $arg_nocache $args
            - proxy_no_cache: $http_secret_header $cookie_nocache $arg_nocache $args
            - add_header: X-Cache-Status $upstream_cache_status


postgres:
  use_upstream_repo: False
  pkgs_extra: [postgresql-contrib]
  manage_force_reload_modules: False
  postgresconf: listen_addresses = '127.0.0.1,{{ private_ip }}'

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
