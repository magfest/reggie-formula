base:
  'vagrant':
    - vagrant
    - postgres
    - rabbitmq
    - nginx
    - redis.server
    - reggie.db
    - reggie.tasks.scheduler
    - reggie.tasks.worker
    - reggie.web
    - reggie.devenv
    - ignore_missing: True
