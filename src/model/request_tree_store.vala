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
        public const string empty_id = "e";
        private const string placeholder_message = _("<empty>");

        enum Columns { NAME, ID, IS_FOLDER, ICON }

        private Gdk.Pixbuf folder_icon;
        private ulong row_inserted_handler;
        private ulong row_deleted_handler;

        public RequestTreeStore() {
            var theme = Gtk.IconTheme.get_default();
            try {
                folder_icon = theme.load_icon("folder-symbolic", Gtk.IconSize.BUTTON, 0);
            } catch (Error e) {
                error("Failed to load icon: %s", e.message);
            }
            set_column_types({typeof(string), typeof(string), typeof(bool), typeof(Gdk.Pixbuf)});
            row_inserted_handler = row_inserted.connect_after(on_row_inserted);
            row_deleted_handler = row_deleted.connect_after(on_row_deleted);
        }

        // Prevent dropping into non-folders.
		bool row_drop_possible(Gtk.TreePath dest_path, Gtk.SelectionData selection_data) {
            Gtk.TreeIter iter;
            if (!get_iter(out iter, dest_path)) return false;
            Value val;

            // Always allow dropping in empty row.
            get_value(iter, Columns.ID, out val);
            if (val.get_string() == empty_id) return base.row_drop_possible(dest_path, selection_data);

            get_value(iter, Columns.IS_FOLDER, out val);
            return !val.get_boolean() && base.row_drop_possible(dest_path, selection_data);
        }

        // Prevent dragging placeholder rows.
        bool row_draggable(Gtk.TreePath path) {
            Gtk.TreeIter iter;
            if (!get_iter(out iter, path)) return false;

            Value val;
            get_value(iter, Columns.ID, out val);
            var id = val.get_string();
            return !(id == placeholder_id || id == empty_id);
        }

        void on_row_inserted(Gtk.TreePath path, Gtk.TreeIter iter) {
            debug("Row inserted: %s", path.to_string());

            // TODO: Solve this with a sort function?
            // Or is the sort order always based on where the user has dropped
            // the node?
            var len = iter_n_children(null);
            if (path.get_indices()[0] >= len - 1) {
                // If row is inserted after the empty placeholder,
                // move the placeholder back to the end.

                Gtk.TreeIter placeholder_iter;
                get_iter(out placeholder_iter, new Gtk.TreePath.from_indices(len-2));

                SignalHandler.block(this, row_deleted_handler);
                SignalHandler.block(this, row_inserted_handler);
                swap(placeholder_iter, iter);
                SignalHandler.unblock(this, row_deleted_handler);
                SignalHandler.unblock(this, row_inserted_handler);
                iter = placeholder_iter;
            }
            
            Gtk.TreeIter parent_iter;
            if (!iter_parent(out parent_iter, iter)) return;

            // If iter has parent, remove placeholder item.

            Gtk.TreeIter child_iter;
            if (!iter_nth_child(out child_iter, parent_iter, 0)) return;

            Value val;

            do {
                get_value(child_iter, Columns.ID, out val);
                if (val.get_string() == placeholder_id) {
                    SignalHandler.block(this, row_deleted_handler);
                    remove(ref child_iter);
                    SignalHandler.unblock(this, row_deleted_handler);
                    return;
                }
            } while(iter_next(ref child_iter));
        }

        void on_row_deleted(Gtk.TreePath path) {
            debug("Row deleted: %s", path.to_string());

            // Add placeholder row if folder is now empty.
            if (path.get_depth() == 1) return;

            if (!path.up()) return;

            Gtk.TreeIter iter;

            if (!get_iter(out iter, path)) return;

            if (iter_n_children(iter) > 0) return;

            Gtk.TreeIter placeholder_iter;
            SignalHandler.block(this, row_inserted_handler);
            append(out placeholder_iter, iter);
            SignalHandler.unblock(this, row_inserted_handler);

            set_placeholder(placeholder_iter);
        }

        public void populate_store(Gee.List<Models.RequestTreeNode> nodes) {
            Gtk.TreeIter iter;
            get_iter_first(out iter);

            SignalHandler.block(this, row_inserted_handler);
            _populate(nodes, iter, null);
            add_empty_node();
            SignalHandler.unblock(this, row_inserted_handler);
        }

        // The empty node at the end is used to drop into the root of the tree.
        private void add_empty_node() {
            Gtk.TreeIter iter;
            append(out iter, null);

            set(iter, 
                Columns.NAME, "",
                Columns.ID, empty_id, 
                Columns.IS_FOLDER, false,
                Columns.ICON, null);
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
