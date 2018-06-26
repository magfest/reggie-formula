# ============================================================================
# Sets up a nice dev environment with a helpful Python REPL and bash aliases.
# ============================================================================

{% for file in ['bash_aliases', 'pythonstartup.py'] %}
reggie /root/.{{ file }}:
  file.managed:
    - name: /root/.{{ file }}
    - source: salt://reggie/devenv/files/{{ file }}
    - template: jinja
{% endfor %}
