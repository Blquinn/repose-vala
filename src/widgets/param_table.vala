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

        //  [GtkChild] private Gtk.TreeViewColumn key_column;
        //  [GtkChild] private Gtk.CellRendererText key_column_renderer;
        //  [GtkChild] private Gtk.TreeViewColumn value_column;
        //  [GtkChild] private Gtk.CellRendererText value_column_renderer;
        //  [GtkChild] private Gtk.TreeViewColumn description_column;
        //  [GtkChild] private Gtk.CellRendererText description_column_renderer;

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

            if (text == "") { // Remove the row
                store.remove(ref iter);
            } else { // Add a new row following
                store.insert(out iter, -1);
                store.set_valuesv(iter, {0, 1, 2}, {"", "", ""});
            }
        }

        [GtkCallback]
        private void on_value_column_renderer_edited(string path, string text) {
            Gtk.TreeIter iter;
            store.get_iter_from_string(out iter, path);
            store.set_value(iter, Column.VALUE, text);
        }

        [GtkCallback]
        private void on_description_column_renderer_edited(string path, string text) {
            Gtk.TreeIter iter;
            store.get_iter_from_string(out iter, path);
            store.set_value(iter, Column.DESCRIPTION, text);
        }

        private void add_row() {
            Gtk.TreeIter it;
            store.append(out it);
            store.set(it, Column.KEY, "", Column.VALUE, "", Column.DESCRIPTION, "");
        }
    }
}