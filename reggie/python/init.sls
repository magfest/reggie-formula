python install:
  pkg.installed:
    - reload_modules: True
    - pkgs:
      - python
      - python-pip
      - python3
      - python3-pip
      - python3-tk
      - libpq-dev        # for psycopg
      - build-essential  # for python-prctl
      - libcap-dev       # for python-prctl
      - libjpeg-dev      # for treepoem
      - ghostscript      # for treepoem

pip install virtualenv:
  pip.installed:
    - name: virtualenv
    - bin_env: /usr/bin/pip3
    - require:
      - python install
