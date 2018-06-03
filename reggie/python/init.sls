python install:
  pkg.installed:
    - reload_modules: True
    - pkgs:
      - python3
      - python3-pip
      - python3-venv
      - python3-tk
      - libpq-dev        # for psycopg
      - build-essential  # for python-prctl
      - libcap-dev       # for python-prctl
      - libjpeg-dev      # for treepoem
      - ghostscript      # for treepoem
