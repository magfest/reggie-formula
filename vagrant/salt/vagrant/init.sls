# ============================================================================
# Generate self-signed certs
# ============================================================================
{%- set certs_dir = salt['pillar.get']('ssl:certs_dir') %}

pip install pyopenssl:
  pip.installed:
    - name: pyopenssl
    - reload_modules: True
    - require:
      - python install

create self signed cert:
  module.run:
    - name: tls.create_self_signed_cert
    - tls_dir: '.'
    - cacert_path: {{ salt['pillar.get']('ssl:dir') }}
    - unless: test -f {{ certs_dir }}/localhost.crt

bundle self signed cert:
  cmd.run:
    - name: cat {{ certs_dir }}/localhost.crt {{ certs_dir }}/localhost.key > {{ certs_dir }}/localhost.pem
    - creates: {{ certs_dir }}/localhost.pem



# ============================================================================
# Vagrant dev environment
# ============================================================================

{% for file in ['bash_aliases', 'pythonstartup.py'] %}
/home/vagrant/.{{ file }}:
  file.managed:
    - name: /home/vagrant/.{{ file }}
    - source: salt://reggie/devenv/files/{{ file }}
    - user: vagrant
    - group: vagrant
    - template: jinja
{% endfor %}

/etc/salt/minion:
  file.managed:
    - name: /etc/salt/minion
    - source: salt://vagrant/files/salt_minion.conf
