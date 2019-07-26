base:
  reggie:
    - vagrant

    - reggie.devenv
    - postgres
    - reggie.db
    - reggie_deploy.glusterfs
    - glusterfs.server
    - haproxy
    - glusterfs.client
    - nginx
    - reggie.web
    - reggie_deploy.web
    - reggie_deploy.sessions
    - redis.server
    - rabbitmq
    - reggie.scheduler
    - reggie.worker

    - ignore_missing: True
