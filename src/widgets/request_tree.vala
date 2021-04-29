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
    public class RequestTree : Gtk.ScrolledWindow {
		[GtkChild] private unowned Gtk.TreeView request_list;

		private Models.RootState root_state;

        public RequestTree(Models.RootState root_state) {
			this.root_state = root_state;
			request_list.model = root_state.request_tree;
		}

		[GtkCallback]
		private bool on_request_list_button_press_event(Gtk.Widget widget, Gdk.EventButton event) {
			// On double left click, expand row
			if (event.type != Gdk.EventType.2BUTTON_PRESS) return false;
			if (event.button != Gdk.BUTTON_PRIMARY) return false;

			Gtk.TreeIter iter;
			request_list.get_selection().get_selected(null, out iter);	
			var path = root_state.request_tree.get_path(iter);
			if (path == null) return true;
			var expanded = request_list.is_row_expanded(path);
			if (expanded) {
				request_list.collapse_row(path);
			} else {
				request_list.expand_row(path, false);
			}
			return true;
		}

		[GtkCallback]
		private void on_request_list_row_activated(Gtk.TreePath path, Gtk.TreeViewColumn column) {
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
    }
}
