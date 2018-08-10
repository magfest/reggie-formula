saltutil.sync_all:
  salt.function:
    - tgt: reggie
    - reload_modules: True

saltutil.refresh_pillar:
  salt.function:
    - tgt: reggie

mine.update:
  salt.function:
    - tgt: reggie

highstate_run:
  salt.state:
    - tgt: reggie
    - highstate: True
