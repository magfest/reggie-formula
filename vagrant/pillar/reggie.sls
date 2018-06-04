reggie:
  user: vagrant
  group: vagrant
  install_dir: /home/vagrant/reggie-formula/reggie-deploy

  plugins:
    ubersystem:
      config:
        celery:
          beat_schedule_filename: /home/vagrant/reggie-formula/reggie-deploy/data/celerybeat-schedule
