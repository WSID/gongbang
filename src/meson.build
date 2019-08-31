gongbang_sources = [
  'gongbanggraph.vala',
  'gongbangloadxml.vala'
]

gongbang_inc = include_directories('.')

gongbang_lib = library('gongbang', gongbang_sources,
  dependencies: [glib, gobject, gio, gobject_introspection]) 

gongbang = declare_dependency (
	dependencies: [glib, gobject, gio, gobject_introspection],
	include_directories: gongbang_inc,
	link_with: gongbang_lib)
