base:
  'vagrant':
    - vagrant
    - reggie.baseline
    - postgres
    - rabbitmq
    - redis.server
    - reggie.db
    - reggie.tasks.scheduler
    - reggie.tasks.worker
    - reggie.web
    - reggie.devenv
