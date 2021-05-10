/* request_tree_store.vala
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

namespace Repose.Models {

    using Repose;

    delegate void UpdateRowFunc(Gtk.TreeIter iter);

    public class RequestTreeStore : Gtk.TreeStore, Gtk.TreeDragDest {

        enum Columns { NAME, ID, IS_FOLDER, ICON }

        private Gdk.Pixbuf folder_icon;

        public RequestTreeStore() {
            var theme = Gtk.IconTheme.get_default();
            try {
                folder_icon = theme.load_icon("folder-symbolic", Gtk.IconSize.BUTTON, 0);
            } catch (Error e) {
                error("Failed to load icon: %s", e.message);
            }
            set_column_types({typeof(string), typeof(string), typeof(bool), typeof(Gdk.Pixbuf)});
        }

        // Prevent dropping into non-folders.
		public bool row_drop_possible(Gtk.TreePath dest_path, Gtk.SelectionData selection_data) {
            Gtk.TreeIter iter;
            if (!get_iter(out iter, dest_path)) return false;
            Value val;
            get_value(iter, Columns.IS_FOLDER, out val);
            return !val.get_boolean();
        }

        public void populate_store(Gee.List<Models.RequestTreeNode> nodes) {
            Gtk.TreeIter iter;
            get_iter_first(out iter);
            _populate(nodes, iter, null);
        }

        private void _populate(Gee.List<Models.RequestTreeNode> nodes, Gtk.TreeIter iter, Gtk.TreeIter? parent) {
            foreach (var node in nodes) {
                append(out iter, parent);

                var name = format_request_name(node.name);

                set(iter, 
                    Columns.NAME, name, 
                    Columns.ID, node.id, 
                    Columns.IS_FOLDER, node.is_folder,
                    Columns.ICON, node.is_folder ? folder_icon : null);

                _populate(node.children, iter, iter);
            }
        }

        private string format_request_name(string name) {
            return name == "" ? "New Request" : name;
        }

        public void update_node(Models.BaseTreeNode node, bool is_update, bool is_folder) {
            var id = node.id;
            var name = format_request_name(node.name);

            if (is_update) {
                // Update existing row.
                @foreach((self, path, iter) => {
                    Value val;
                    get_value(iter, Columns.ID, out val);
                    if (val.get_string() == id) {
                        set(iter, Columns.NAME, name);
                        return true;
                    }
                    return false;
                });
                return;
            }

            // Add row.
            Gtk.TreeIter new_iter;
            if (node.parent_id == null) {
                append(out new_iter, null);
            } else {
                // Find parent iter.
                Gtk.TreeIter? parent_iter = null;
                @foreach((self, path, iter) => {
                    Value val;
                    get_value(iter, Columns.ID, out val);
                    if (val.get_string() == node.parent_id) {
                        parent_iter = iter;
                        return true;
                    }
                    return false;
                });
                append(out new_iter, parent_iter);
            }

            set(new_iter, 
                Columns.NAME, name, 
                Columns.ID, node.id, 
                Columns.IS_FOLDER, is_folder,
                Columns.ICON, is_folder ? folder_icon : null);
        }
    }
}
