/* main_window.vala
 *
 * Copyright 2021 Benjamin Quinn
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

namespace Repose.Widgets {

	using Repose;

	[GtkTemplate(ui = "/me/blq/Repose/ui/MainWindow.ui")]
    public class MainWindow : Gtk.Window {
		//  [GtkChild] private Gtk.Paned request_pane;
		[GtkChild] private Gtk.ListBox request_list;
		[GtkChild] private Gtk.Box active_requests_notebook_box;
		[GtkChild] private Gtk.Notebook active_requests_notebook;
		[GtkChild] private Gtk.Stack editor_placeholder_stack;
		[GtkChild] private Gtk.Label no_request_selected_label;
		[GtkChild] private Gtk.HeaderBar header_bar;
		//  [GtkChild] private Gtk.Button new_request_button;
		private Gtk.ToggleButton show_saved_requests_button;

		private RequestEditor request_editor;
		private Models.RootState root_state;

		public MainWindow(Gtk.Application app) {
			GLib.Object(application: app);
			
			root_state = new Models.RootState();

			var col_1 = new Models.CollectionModel();
			col_1.name = "Collection 1";
			var req_1 = new Models.Request("Request 1", "https://example.com", "GET");
			var req_node_1 = new Models.RequestTreeNode(new Models.FolderModel("Folder 1"), req_1);
			var req_node_2 = new Models.RequestTreeNode(null, req_1);
			req_node_1.add_child(req_node_2);
			col_1.populate_collection({req_node_1});
			//  col_1.add_child(req_node_1);
			root_state.collections.append(col_1);

			request_list.bind_model(root_state.collections, (collection) => {
				return new Collection((Models.CollectionModel) collection);
			});

			//  try {
			//  	var icon = new Gdk.Pixbuf.from_resource("/me/blq/Repose/resources/img/nightcap-round-grey-100x100.png");
			//  	set_icon(icon);
			//  } catch (Error e) {
			//  	warning("Failed to load application icon: %s", e.message);
			//  }

			show_saved_requests_button = new Gtk.ToggleButton();
			show_saved_requests_button.visible = true;
			show_saved_requests_button.tooltip_text = "Show or hide the left side-bar.";
			var srbi = new Gtk.Image.from_icon_name("view-dual-symbolic", Gtk.IconSize.BUTTON);
			srbi.visible = true;
			show_saved_requests_button.child = srbi;
			header_bar.pack_end(show_saved_requests_button);

			root_state.bind_property("is_request_list_open", request_list, "visible");
			show_saved_requests_button.bind_property("active", root_state, "is_request_list_open");

			request_editor = new RequestEditor(root_state);
			active_requests_notebook_box.pack_end(request_editor, true, true);

			// Keep notebook tabs in sync with active_request_items.
			root_state.active_requests.items_changed.connect(on_active_requests_items_changed);
			root_state.active_request_changed.connect(on_active_request_changed);
			active_requests_notebook.switch_page.connect(on_requests_notebook_page_changed);
		}

		[GtkCallback]
		private void on_new_request_button_clicked(Gtk.Button btn) {
			root_state.add_new_request();
		}

		private void on_requests_notebook_page_changed(Gtk.Widget page_widget, uint page) {
			message("Notebook changed to page: %d", (int) page);
			root_state.active_request = (Models.Request)root_state.active_requests.get_object(page);
		}

		private void on_active_request_changed() {
			if (root_state.active_request == null) {
				editor_placeholder_stack.visible_child = no_request_selected_label;
				return;
			} else {
				editor_placeholder_stack.visible_child = active_requests_notebook_box;
			}

			message("Active request changed to: %s", root_state.active_request.name);

			uint pos;
			root_state.active_requests.find(root_state.active_request, out pos);

			message("Notebook changing to position: %d of %d", (int) pos, (int)root_state.active_requests.get_n_items());

			active_requests_notebook.switch_page.disconnect(on_requests_notebook_page_changed);
			active_requests_notebook.set_current_page((int) pos);
			active_requests_notebook.switch_page.connect(on_requests_notebook_page_changed);
		}

		private void on_active_requests_items_changed(uint pos, uint removed, uint added) {
			// Assume only 1 item changing at a time.
			message("Active requests changed pos: %u, removed: %u, added: %u", pos, removed, added);

			for (int i = 0; i < added; i++) {
				var req = (Models.Request) root_state.active_requests.get_item(pos+i);
				var placeholder = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
				placeholder.visible = true;
				active_requests_notebook.append_page(
					placeholder, 
					new Widgets.ActiveRequestTab(root_state, req)
				);
			}

			for (int i = 0; i < removed; i++) {
				active_requests_notebook.remove_page((int)pos+i);
			}
		}
    }
}
