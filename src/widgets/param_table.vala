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

        private Gtk.ListStore store;

        public ParamTable() {
            store = new Gtk.ListStore(3, typeof(string), typeof(string), typeof(string));
            set_model(store);
            add_row();
        }

        [GtkCallback]
        private void on_key_column_renderer_edited() {}

        [GtkCallback]
        private void on_value_column_renderer_edited() {}

        [GtkCallback]
        private void on_description_column_renderer_edited() {}

        private void add_row() {
            Gtk.TreeIter it;
            store.append(out it);
            store.set(it, Column.KEY, "", Column.VALUE, "", Column.DESCRIPTION, "");
        }
    }
}