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
		[GtkChild] private unowned Gtk.TreeStore request_list_store;

        public RequestTree() {
			//  request_list_store
			// Populate with test data.

			Gtk.TreeIter iter;
			request_list_store.append(out iter, null);
			request_list_store.set(iter, 0, "Collection 1");
			Gtk.TreeIter child_iter;
			request_list_store.append(out child_iter, iter);
			request_list_store.set(child_iter, 0, "Folder 1");
			Gtk.TreeIter child_iter_2;
			request_list_store.append(out child_iter_2, child_iter);
			request_list_store.set(child_iter_2, 0, "Request 1");

			Gtk.TreeIter child_iter_n;
			for (var i = 2; i < 200; i++) {
				request_list_store.append(out child_iter_n, child_iter);
				request_list_store.set(child_iter_n, 0, "Request %d".printf(i));
			}
        }

		[GtkCallback]
		private bool on_request_list_button_press_event(Gtk.Widget widget, Gdk.EventButton event) {
			// On double left click, expand row
			if (event.type != Gdk.EventType.2BUTTON_PRESS) return false;
			if (event.button != Gdk.BUTTON_PRIMARY) return false;

			Gtk.TreeIter iter;
			request_list.get_selection().get_selected(null, out iter);	
			var path = request_list_store.get_path(iter);
			if (path == null) return true;
			var expanded = request_list.is_row_expanded(path);
			if (expanded) {
				request_list.collapse_row(path);
			} else {
				request_list.expand_row(path, false);
			}
			return true;
		}
    }
}
