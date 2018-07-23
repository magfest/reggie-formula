{%- from 'reggie/map.jinja' import reggie with context -%}
{%- from 'reggie/macros.jinja' import systemd_service with context %}

{{ systemd_service(
    'reggie-worker',
    exec_start=reggie.install_dir ~ '/env/bin/celery -A uber.tasks worker --loglevel=info',
    description='Reggie celery worker service',
    includes=['reggie.install'],
    watch_any=['sls: reggie.install'],
    logfile='/var/log/reggie/worker.log',
    part_of='reggie.service',
    user=reggie.user
) }}
