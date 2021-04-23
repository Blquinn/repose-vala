/* param_table.vala
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
	[GtkTemplate(ui = "/me/blq/Repose/ui/ParamTable.ui")]
    public class ParamTable : Gtk.TreeView {
        enum Column {
            KEY,
            VALUE,
            DESCRIPTION,
        }

        //  [GtkChild] private unowned Gtk.TreeViewColumn key_column;
        //  [GtkChild] private unowned Gtk.CellRendererText key_column_renderer;
        //  [GtkChild] private unowned Gtk.TreeViewColumn value_column;
        //  [GtkChild] private unowned Gtk.CellRendererText value_column_renderer;
        //  [GtkChild] private unowned Gtk.TreeViewColumn description_column;
        //  [GtkChild] private unowned Gtk.CellRendererText description_column_renderer;

        private Models.ParamTableListStore store;

        private unowned Gtk.CellEditable? current_editable;

		public new void set_model(Models.ParamTableListStore? model) {
            store = model;
            base.set_model(model);

            store.row_inserted.connect(on_row_inserted);

            // Initialze model with empty row.
            if (model.iter_n_children(null) == 0) {
                add_row();
            }
        }

        [GtkCallback]
        private void on_renderer_editing_started(Gtk.CellEditable editable, string path) {
            current_editable = editable;
        }
        
        [GtkCallback]
        private void on_renderer_editing_cancelled() {
            current_editable = null;
        }

        private void on_row_inserted(Gtk.TreePath path, Gtk.TreeIter iter) {
            var idx = path.get_indices()[0];
            var len = store.iter_n_children(null);

            // Usually this happens with drag and drop.
            // If a non-empty row is inserted at the end, we need to clean up the
            // final empty row, which is now before this row.
            if (idx == len-1 && !is_row_empty(idx) && idx > 0 && is_row_empty(idx-1)) {
                var position = iter.copy();
                store.iter_previous(ref iter);
                store.move_after(ref iter, position);
            }
        }
        
        [GtkCallback]
        private bool on_key_press_event(Gdk.EventKey key) {
            if (key.keyval != Gdk.Key.Tab) return false;

            // On tab, select next cell.
            Gtk.TreePath? path;
            Gtk.TreeViewColumn? col;
            get_cursor(out path, out col);
            if (path == null || col == null) return false;

            if (current_editable == null) return true;

            var len = store.iter_n_children(null);
            var columns = get_columns();
            var row_idx = path.get_indices()[0];
            var col_idx = columns.index(col);

            current_editable.editing_done();

            if (col_idx < 2) { // Move to next column
                set_cursor(path, columns.nth_data(col_idx+1), true);
            } else { // Move to next row
                if (row_idx == len-1) add_row_if_last_not_empty();
                path.next();
                set_cursor(path, columns.nth_data(0), true);
            }

            return true;
        }

        [GtkCallback]
        private void on_key_column_renderer_edited(string path, string text) {
            Gtk.TreeIter iter;
            store.get_iter_from_string(out iter, path);
            store.set_value(iter, Column.KEY, text);

            on_row_edited(iter);
        }

        [GtkCallback]
        private void on_value_column_renderer_edited(string path, string text) {
            Gtk.TreeIter iter;
            store.get_iter_from_string(out iter, path);
            store.set_value(iter, Column.VALUE, text);

            on_row_edited(iter);
        }

        [GtkCallback]
        private void on_description_column_renderer_edited(string path, string text) {
            Gtk.TreeIter iter;
            store.get_iter_from_string(out iter, path);
            store.set_value(iter, Column.DESCRIPTION, text);

            on_row_edited(iter);
        }

        private void on_row_edited(Gtk.TreeIter iter) {
            var idx = store.get_path(iter).get_indices()[0];

            if (is_row_empty(idx)) {
                var length = store.iter_n_children(null);
                if (idx == length-1) return;
                
                // Otherwise remove and add row to end.
                store.remove(ref iter);
            }

            add_row_if_last_not_empty();
        }

        private void add_row_if_last_not_empty() {
            if (!is_row_empty(store.iter_n_children(null) - 1)) {
                add_row();
            }
        }

        private void add_row() {
            Gtk.TreeIter it;
            store.append(out it);
            store.set(it, Column.KEY, "", Column.VALUE, "", Column.DESCRIPTION, "");
        }

        private bool is_row_empty(int i) {
            Gtk.TreeIter it;
            store.iter_nth_child(out it, null, i);
            Value val;
            store.get_value(it, Column.KEY, out val);
            if (val.get_string() != "") return false;
            store.get_value(it, Column.VALUE, out val);
            if (val.get_string() != "") return false;
            store.get_value(it, Column.DESCRIPTION, out val);
            if (val.get_string() != "") return false;
            return true;
        }
    }
}
