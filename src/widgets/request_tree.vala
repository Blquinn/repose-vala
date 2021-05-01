/* request_tree.vala
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

	[GtkTemplate(ui = "/me/blq/Repose/ui/RequestTree.ui")]
    public class RequestTree : Gtk.Box {
		[GtkChild] private unowned Gtk.TreeView request_list;
		[GtkChild] private unowned Gtk.EntryCompletion search_entry_completion;
		[GtkChild] private unowned Gtk.SearchEntry search_entry;

		public bool search_active { get; set; default = false; }

		private Gtk.TreeModelFilter request_tree_filter;
		private Models.RootState root_state;

        public RequestTree(Models.RootState root_state) {
			this.root_state = root_state;
			//  request_list.model = root_state.request_tree;
			request_list.model = root_state.request_tree;
			request_tree_filter = new Gtk.TreeModelFilter(root_state.request_tree, null);
			request_tree_filter.set_visible_func(request_tree_visible);
			search_entry_completion.model = root_state.request_tree;
			search_entry_completion.text_column = 0;


			search_entry.bind_property("text", this, "search_active", BindingFlags.DEFAULT, (_, from, ref to) => {
				bool current = search_active;
				bool new_val = from.get_string() != "";
				to.set_boolean(new_val);
				return current != new_val;
			});

			// Disable drag and drop while search is active.
			bind_property("search_active", request_list, "reorderable", BindingFlags.DEFAULT, (_, from, ref to) => {
				to.set_boolean(!from.get_boolean());
				return true;
			});

			notify.connect((param) => {
				if (param.name != "search-active") return;

				// Only use the filter model if the search is active.
				if (search_active) {
					request_list.model = request_tree_filter;
				} else {
					request_list.model = root_state.request_tree;
				}
			});
		}

		[GtkCallback]
		private bool on_request_list_button_press_event(Gtk.Widget widget, Gdk.EventButton event) {
			// On double left click, expand row
			if (event.type != Gdk.EventType.2BUTTON_PRESS) return false;
			if (event.button != Gdk.BUTTON_PRIMARY) return false;

			Gtk.TreeIter iter;
			request_list.get_selection().get_selected(null, out iter);	

			Gtk.TreePath path;
			if (search_active) {
				var filter_path = request_tree_filter.get_path(iter);
				path = request_tree_filter.convert_path_to_child_path(filter_path);
			} else {
				path = root_state.request_tree.get_path(iter);
			}
			var expanded = request_list.is_row_expanded(path);
			if (expanded) {
				request_list.collapse_row(path);
			} else {
				request_list.expand_row(path, false);
			}
			return true;
		}

		[GtkCallback]
		private void on_request_list_row_activated(Gtk.TreePath filter_path, Gtk.TreeViewColumn column) {
			var path = search_active ? request_tree_filter.convert_path_to_child_path(filter_path) : filter_path;

			Gtk.TreeIter iter;
			if (!root_state.request_tree.get_iter(out iter, path)) return;
			Value val;

			root_state.request_tree.get_value(iter, Models.RequestTreeStore.Columns.IS_FOLDER, out val);
			if (val.get_boolean()) return;

			root_state.request_tree.get_value(iter, Models.RequestTreeStore.Columns.ID, out val);

			try {
				root_state.load_request_by_id(val.get_string());
			} catch (Error e) {
				warning("Failed to load activated request: %s", e.message);
			}
		}

		[GtkCallback]
		private void on_new_folder_button_clicked() {
			debug("Showing folder dialog.");
			var diag = new Widgets.FolderDialog();
			diag.set_transient_for((Gtk.Window) get_toplevel());
			diag.show_all();
		}

		[GtkCallback]
		private void on_search_entry_search_changed() {
			request_tree_filter.refilter();
		}

		private bool request_tree_visible(Gtk.TreeModel model, Gtk.TreeIter iter) {
			var text = search_entry.text.down();
			if (text == "") return true;

			Value val;
			model.get_value(iter, 0, out val);

			var name = val.get_string().down();
			return name.contains(text);
		}
    }
}
