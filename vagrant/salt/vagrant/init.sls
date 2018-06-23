# ============================================================================
# Generate self-signed certs
# ============================================================================

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
    - cacert_path: '/etc/ssl'
    - unless: test -f /etc/ssl/certs/localhost.crt


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
