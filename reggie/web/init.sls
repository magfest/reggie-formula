{%- from 'reggie/map.jinja' import reggie with context -%}
{%- from 'reggie/macros.jinja' import systemd_service with context -%}

{{ systemd_service(
    'reggie-web',
    exec_start=reggie.install_dir ~ '/env/bin/python ' ~ reggie.install_dir ~ '/sideboard/run_server.py',
    description='Reggie web service',
    includes=['reggie.install'],
    watch_any=['sls: reggie.install'],
    logfile='/var/log/reggie/web.log',
    part_of='reggie.service',
    user=reggie.user
) }}
