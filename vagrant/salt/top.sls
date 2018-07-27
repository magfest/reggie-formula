base:
  'vagrant':
    - vagrant
    - reggie.devenv
    - reggie_deploy.ssl
    - reggie_deploy.glusterfs
    - glusterfs.server
    - glusterfs.client
    - haproxy
    - nginx.ng
    - postgres
    - rabbitmq
    - redis.server
    - reggie.db
    - reggie.scheduler
    - reggie.worker
    - reggie.web
    - reggie_deploy.web
    - ignore_missing: True
