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

    public class RequestTreeStore : Gtk.TreeStore, Gtk.TreeDragDest, Gtk.TreeDragSource {

        public const string placeholder_id = "p";
        private const string placeholder_message = _("<empty>");

        private bool is_populating = false;

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
            row_inserted.connect(on_row_inserted);
            row_deleted.connect(on_row_deleted);
        }

        // Prevent dropping into non-folders.
		bool row_drop_possible(Gtk.TreePath dest_path, Gtk.SelectionData selection_data) {
            Gtk.TreeIter iter;
            if (!get_iter(out iter, dest_path)) return false;
            Value val;
            get_value(iter, Columns.IS_FOLDER, out val);
            return !val.get_boolean();
        }

        // Prevent dragging placeholder rows.
        bool row_draggable(Gtk.TreePath path) {
            Gtk.TreeIter iter;
            if (!get_iter(out iter, path)) return false;

            Value val;
            get_value(iter, Columns.ID, out val);
            return val.get_string() != placeholder_id;
        }

        void on_row_inserted(Gtk.TreePath path, Gtk.TreeIter iter) {
            if (is_populating) return;
            debug("Row inserted: %s", path.to_string());

            Gtk.TreeIter parent_iter;
            if (!iter_parent(out parent_iter, iter)) return;

            // If iter has parent, remove placeholder item.

            Gtk.TreeIter child_iter;
            if (!iter_nth_child(out child_iter, parent_iter, 0)) return;

            do {
                Value val;
                get_value(child_iter, Columns.ID, out val);
                if (val.get_string() == placeholder_id) {
                    row_deleted.disconnect(on_row_deleted);
                    remove(ref child_iter);
                    row_deleted.connect(on_row_deleted);
                    return;
                }
            } while(iter_next(ref child_iter));
        }

        void on_row_deleted(Gtk.TreePath path) {
            if (is_populating) return;
            debug("Row deleted: %s", path.to_string());

            // Add placeholder row if folder is now empty.

            //  if (!path.up()) return;
            if (!path.up()) return;

            Gtk.TreeIter iter;
            if (!get_iter(out iter, path)) return;

            Gtk.TreeIter placeholder_iter;
            row_inserted.disconnect(on_row_inserted);
            append(out placeholder_iter, iter);
            row_inserted.connect(on_row_inserted);

            set_placeholder(placeholder_iter);
        }

        public void populate_store(Gee.List<Models.RequestTreeNode> nodes) {
            Gtk.TreeIter iter;
            get_iter_first(out iter);
            is_populating = true;
            _populate(nodes, iter, null);
            is_populating = false;
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

                // Add empty folder placeholder.
                if (node.is_folder && node.children.is_empty) {
                    Gtk.TreeIter placeholder_iter;
                    append(out placeholder_iter, iter);

                    set_placeholder(placeholder_iter);
                }

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

            // Add empty folder placeholder.
            if (is_folder) {
                Gtk.TreeIter placeholder_iter;
                append(out placeholder_iter, new_iter);
                set_placeholder(placeholder_iter);
            }
        }

        private void set_placeholder(Gtk.TreeIter iter) {
            set(iter, 
                Columns.NAME, placeholder_message,
                Columns.ID, placeholder_id, 
                Columns.IS_FOLDER, false,
                Columns.ICON, null);
        }
    }
}
