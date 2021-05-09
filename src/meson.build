repose_sources = [
  'main.vala',
  'model/base_tree_node.vala',
  'model/request.vala',
  'model/response.vala',
  'model/root_state.vala',
  'model/param_row.vala',
  'model/param_table_list_store.vala',
  'model/collection_model.vala',
  'model/folder_model.vala',
  'model/request_tree_node.vala',
  'model/request_tree_store.vala',
  'model/db/request_row.vala',
  'widgets/main_window.vala',
  'widgets/request_editor.vala',
  'widgets/request_container.vala',
  'widgets/response_container.vala',
  'widgets/param_table.vala',
  'widgets/active_request_tab.vala',
  'widgets/collection.vala',
  'widgets/request_tree.vala',
  'widgets/folder_dialog.vala',
  'widgets/create_folder_dialog.vala',
  'widgets/save_request_dialog.vala',
  'services/http_client.vala',
  'services/request_dao.vala',
  'utils/humanize.vala',
  'utils/hex_dump.vala',
  'utils/editor_langs.vala',
  'utils/dirs.vala',
]

vapi_dir = meson.current_source_dir() / 'vapi'

add_project_arguments('-DG_LOG_DOMAIN="Repose"', language : 'c')
add_project_arguments('-DGETTEXT_PACKAGE="gettext"', language : 'c')
add_project_arguments(['--vapidir', vapi_dir], language: 'vala')

cc = meson.get_compiler('c')
repose_deps = [
  dependency('gio-2.0', version: '>= 2.50', required: true),
  dependency('glib-2.0', version: '>= 2.50', required: true),
  dependency('gtk+-3.0', version: '>= 3.22', required: true),
  dependency('gtksourceview-4', required: true),
  dependency('libsoup-2.4', required: true),
  dependency('json-glib-1.0', required: true),
  dependency('template-glib-1.0', required: true),
  dependency('libxml-2.0', required: true),
  dependency('uchardet', required: true),
  dependency('gee-0.8', version: '>= 0.8.5', required: true),
  dependency('sqlite3', required: true),
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
