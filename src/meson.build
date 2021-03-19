repose_sources = [
  'main.vala',
  'model/request.vala',
  'model/response.vala',
  'model/root_state.vala',
  'model/param_row.vala',
  'widgets/main_window.vala',
  'widgets/request_editor.vala',
  'widgets/request_container.vala',
  'widgets/response_container.vala',
  'widgets/param_table.vala',
  'services/http_client.vala',
]

repose_deps = [
  dependency('gio-2.0', version: '>= 2.50'),
  dependency('gtk+-3.0', version: '>= 3.22'),
  dependency('gtksourceview-4'),
  dependency('libsoup-2.4'),
  dependency('json-glib-1.0'),
]

gnome = import('gnome')

repose_sources += gnome.compile_resources('repose-resources',
  'repose.gresource.xml',
  c_name: 'repose'
)

executable('repose', 
  repose_sources,
  vala_args: '--target-glib=2.50',
  dependencies: repose_deps,
  install: true,
)
