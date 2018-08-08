{%- from 'macros.jinja' import nginx_ssl_config, nginx_proxy_config -%}
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
  data_dir: /home/vagrant/reggie_data
  mounted_data_dir: /home/vagrant/reggie_data/mnt

  plugins:
    magprime:
      name: magprime
      source: https://github.com/magfest/magprime.git

    ubersystem:
      config:
        path: ''
        hostname: 'localhost:4443'

        code_of_conduct_url: 'http://super.magfest.org/codeofconduct'
        consent_form_url: 'http://super.magfest.org/parentalconsentform'
        contact_url: 'http://super.magfest.org/contact'
        prereg_faq_url: 'http://super.magfest.org/faq'

        panels_twilio_number: '+12405415595'
        tabletop_twilio_number: '+15713646627'

        preassigned_badge_types: ['staff_badge', 'supporter_badge']

        admin_email: MAGFest Sys Admin <sysadmin@magfest.org>
        developer_email: MAGFest Software <code@magfest.org>
        security_email: MAGFest Security <security@magfest.org>

        regdesk_email: MAGFest Registration <regsupport@magfest.org>
        regdesk_email_signature: '- MAGFest Registration Department'

        staff_email: MAGFest Staffing <stops@magfest.org>
        stops_email_signature: '- MAGFest Staff Operations'

        marketplace_email: MAGFest Marketplace <marketplace@magfest.org>
        marketplace_email_signature: '- MAGFest Marketplace'

        panels_email: MAGFest Panels <panels@magfest.org>
        peglegs_email_signature: '- MAGFest Panels Department'

        guest_email: MAGFest Guests <guests@magfest.org>
        guest_email_signature: '- MAGFest Guest Department'

        band_email: MAGFest Music Department <music@magfest.org>
        band_email_signature: '- MAGFest Music Department'

        prereg_hotel_info_email_sender: Do Not Reply <noreply@magfest.org>
        prereg_hotel_info_email_signature: '- MAGFest'

        secret:
          barcode_key: 'TEST_ONLY'
          barcode_salt: 255
          barcode_event_id: 255

        enums:
          interest:
            lan: LAN

          job_location:
            chipspace: Chipspace
            food_prep: Staff Suite
            staff_support: Staff Support
            tabletop: Tabletop
            tech_ops: Tech Ops


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
  enabled: True
  overwrite: True

  global:
    tune.ssl.default-dh-param: 2048

  listens:
    reggie_http_to_https_redirect:
      mode: http
      bind: '0.0.0.0:8000'
      httprequests: 'redirect location https://%[hdr(host),regsub(:8000,:4443,i)]%[capture.req.uri] code 301'

  frontends:
    reggie_load_balancer:
      mode: http
      bind: '0.0.0.0:4443 ssl crt {{ certs_dir }}/{{ minion_id }}.pem'
      redirects: 'scheme https code 301 if !{ ssl_fc }'

      acls:
        {%- for header in ['Location', 'Refresh'] %}
        - 'header_{{ header|lower }}_exists res.hdr({{ header }}) -m found'
        {%- endfor %}

        {%- for path in ['reggie', 'uber', 'profiler', 'stats'] %}
        - 'path_is_{{ path }} path -i /{{ path }}'
        - 'path_starts_with_{{ path }} path_beg -i /{{ path }}/'
        {%- endfor %}

        - 'path_starts_with_static path_beg -i /reggie/static/ /reggie/static_views/ /static/ /static_views/'

      options:
        - forwardfor

      httprequests:
        - 'set-header X-Real-IP %[src]'
        {%- for path in ['reggie', 'uber'] %}
        - 'redirect location https://%[hdr(host)]%[url,regsub(^/{{ path }}/?,/,i)] code 302 if path_is_{{ path }} OR path_starts_with_{{ path }}'
        {%- endfor %}
        - 'set-path /reggie%[path] if !path_is_profiler !path_starts_with_profiler !path_is_stats !path_starts_with_stats'

      httpresponses:
        {%- for header in ['Location', 'Refresh'] %}
        - 'replace-value {{ header }} https://([^/]*)(?:/reggie)?(.*) https://\1:4443\2 if header_{{ header|lower }}_exists'
        {%- endfor %}

      use_backends: 'reggie_http_backend if path_starts_with_static'
      default_backend: 'reggie_https_backend'

  backends:
    reggie_https_backend:
      mode: http
      servers:
        reggie_https_server:
          host: {{ private_ip }}
          port: 443
          extra: 'ssl verify none'

    reggie_http_backend:
      mode: http
      servers:
        reggie_http_server:
          host: {{ private_ip }}
          port: 80


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
              - listen: '127.0.0.1:443 ssl'
              - listen: '{{ private_ip }}:443 ssl'
              {{ nginx_ssl_config(
                  certs_dir ~ '/' ~ minion_id ~ '.key',
                  certs_dir ~ '/' ~ minion_id ~ '.crt',
                  certs_dir ~ '/dhparams.pem')|indent(14) }}

              {%- for location in ['/preregistration/form'] %}
              - 'location = /reggie{{ location }}':
                - proxy_hide_header: Cache-Control
                {{ nginx_proxy_config(cache='/etc/nginx/reggie_short_term_cache.conf')|indent(16) }}
              {%- endfor %}

              {%- for location in ['/static/', '/static_views/'] %}
              - 'location /reggie{{ location }}':
                {{ nginx_proxy_config(cache='/etc/nginx/reggie_long_term_cache.conf')|indent(16) }}
              {%- endfor %}

              - 'location /':
                {{ nginx_proxy_config()|indent(16) }}

            - server:
              - server_name: localhost
              - listen: '127.0.0.1:80'
              - listen: '{{ private_ip }}:80'

              - access_log: /var/log/nginx/access_static.log
              - error_log: /var/log/nginx/error_static.log

              {%- for location in ['/static/', '/static_views/'] %}
              - 'location /reggie{{ location }}':
                {{ nginx_proxy_config(cache='/etc/nginx/reggie_long_term_cache.conf')|indent(16) }}
              {%- endfor %}

              - 'location /':
                - return: '301 https://$host:443$request_uri'

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
