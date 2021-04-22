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

		public new void set_model(Models.ParamTableListStore? model) {
            store = model;
            base.set_model(model);
            if (model.iter_n_children(null) == 0) {
                add_row();
            }
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
            Value key;
            store.get_value(iter, Column.KEY, out key);
            Value val;
            store.get_value(iter, Column.VALUE, out val);

            // Row is empty

            if (key.get_string() == "" && val.get_string() == "") {
                store.remove(ref iter);
            }

            add_row_if_last_not_empty();
        }

        private void add_row_if_last_not_empty() {
            Gtk.TreeIter it;
            store.get_iter_first(out it);
            var children = store.iter_n_children(null);

            // If the last row is not empty, we need to add an additional empty row.

            if (!is_row_empty(children-1)) {
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
            store.get_iter_first(out it);
            store.iter_nth_child(out it, null, i);
            Value val;
            store.get_value(it, Column.KEY, out val);
            if (val.get_string() != "") return false;
            store.get_value(it, Column.VALUE, out val);
            if (val.get_string() != "") return false;
            return true;
        }
    }
}