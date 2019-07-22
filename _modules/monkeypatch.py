
def ordered_yaml():
    import salt.utils.data
    import salt.utils.yamlloader
    from salt.utils.odict import OrderedDict

    if not hasattr(salt.utils.data.decode, '_patched'):
        _original_decode = salt.utils.data.decode
        def _ordered_decode(
                data,
                encoding=None,
                errors='strict',
                keep=False,
                normalize=False,
                preserve_dict_class=True,
                preserve_tuples=False,
                to_str=False):
            # Overridden to change default value of preserve_dict_class to True.
            return _original_decode(data, encoding, errors, keep, normalize, preserve_dict_class, preserve_tuples, to_str)
        _ordered_decode._patched = True
        salt.utils.data.decode = _ordered_decode

    if not hasattr(salt.utils.yamlloader.SaltYamlSafeLoader.__init__, '_patched'):
        _original_SaltYamlSafeLoader_init = salt.utils.yamlloader.SaltYamlSafeLoader.__init__
        def _ordered_SaltYamlSafeLoader_init(self, stream, dictclass=OrderedDict):
            # Overridden to change default value of dictclass to OrderedDict.
            return _original_SaltYamlSafeLoader_init(self, stream, dictclass)
        _ordered_SaltYamlSafeLoader_init._patched = True
        salt.utils.yamlloader.SaltYamlSafeLoader.__init__ = _ordered_SaltYamlSafeLoader_init

    return ''
