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
  'widgets/active_request_tab.vala',
  'services/http_client.vala',
  'utils/humanize.vala',
  'utils/hex_dump.vala',
]

vapi_dir = meson.current_source_dir() / 'vapi'

add_project_arguments(['--vapidir', vapi_dir], language: 'vala')

# subproject('gtksourceview')
# gtksource_dep = subproject('gtksourceview').get_variable('gtksource_dep')
# gtksv_dep = 

#
# gtksource_lib = 'gtksourceview-5'
# gtksource_lib_dir = '/usr/local/lib64'
# # gtksource_header_dir = '/usr/local/include'
# gtksource_header_dir = '/usr/local/include/gtksourceview-5/gtksourceview'
# gtksource_vapi_dir = '/usr/local/share/vala/vapi'

# gtksource_dep = declare_dependency(
#     link_args : ['-L' + gtksource_lib_dir, '-l' + gtksource_lib],
#     include_directories : include_directories([gtksource_header_dir, gtksource_vapi_dir]))

cc = meson.get_compiler('c')
repose_deps = [
  dependency('gio-2.0', version: '>= 2.50', required: true),
  dependency('glib-2.0', version: '>= 2.50', required: true),
  dependency('gtk4', required: true),
  # gtksv_proj,
  dependency('gtksourceview-5', version: '>= 5.0', required: true),
  # gtksource_dep,
  # gtksource_dep,
  dependency('libsoup-2.4', required: true),
  dependency('json-glib-1.0', required: true),
  dependency('uchardet', required: true),
  cc.find_library('m', required : true),
]

gnome = import('gnome')

repose_sources += gnome.compile_resources('repose-resources',
  'repose.gresource.xml',
  c_name: 'repose'
)

repose_exe = executable('repose', 
  repose_sources,
  vala_args: '--target-glib=2.50',
  dependencies: repose_deps,
  install: true,
)

subdir('tests')
