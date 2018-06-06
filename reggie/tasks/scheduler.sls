{%- from 'reggie/map.jinja' import reggie with context -%}
{%- from 'reggie/macros.jinja' import systemd_service with context -%}

{{ systemd_service(
    'reggie-scheduler',
    exec_start=reggie.install_dir ~ '/env/bin/celery -A uber.tasks beat --loglevel=info',
    description='Reggie celery beat scheduler service',
    working_dir=reggie.data_dir,
    includes=['reggie.install'],
    watch_any=['sls: reggie.install'],
    logfile='/var/log/reggie/scheduler.log',
    part_of='reggie.service',
    user=reggie.user
) }}
