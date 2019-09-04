
gongbang_doc = custom_target('gongbang-0.0',
  command: [valadoc, '@INPUT@', '--force', '-o', '@OUTPUT@', '--pkg=glib-2.0', '--pkg=gobject-2.0', '--pkg=gio-2.0', '--pkg=gobject-introspection-1.0', '--package-name=gongbang', '--package-version=0.0'],
  input: gongbang_sources,
  output: 'gongbang',
  build_by_default: true,
  )
