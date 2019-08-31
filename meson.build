project('gongbang', ['c', 'vala'],
        version: '0.1.0',
  meson_version: '>= 0.40.0',
)


glib = dependency('glib-2.0')
gobject = dependency('gobject-2.0')
gio = dependency('gio-2.0')
gobject_introspection = dependency('gobject-introspection-1.0')


subdir('src')
subdir('test')


# valadoc option: Build documens.

option_doc = get_option('valadoc')
valadoc = find_program('valadoc', required: option_doc)

if (option_doc.enabled() or valadoc.found())
  subdir('doc')
endif
