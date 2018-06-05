reggie:
  user: vagrant
  group: vagrant
  install_dir: /home/vagrant/reggie-formula/reggie-deploy

  plugins:
    magprime:
      name: magprime
      source: https://github.com/magfest/magprime.git

redis:
  user: reggie
  pass: reggie
  port: 6379
  bind: 127.0.0.1
