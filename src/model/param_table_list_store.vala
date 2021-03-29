/* param_table_list_store.vala
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

    public class ParamTableListStore : Gtk.ListStore {
        enum Column {
            KEY,
            VALUE,
            DESCRIPTION,
        }

        public ParamTableListStore() {
            set_column_types({typeof(string), typeof(string), typeof(string)});
            add_row();
        }

        public void add_row() {
            Gtk.TreeIter it;
            append(out it);
            this.set(it, Column.KEY, "", Column.VALUE, "", Column.DESCRIPTION, "");
        }

        public void prepent_or_udpate_row_by_key(Models.ParamRow row) {
            Gtk.TreeIter iter;
            get_iter_first(out iter);

            do {
                Value val;
                get_value(iter, Column.KEY, out val);
                if (val.get_string() == row.key) {
                    set_value(iter, Column.VALUE, row.value);
                    set_value(iter, Column.DESCRIPTION, row.description);
                    return;
                }
            } while(iter_next(ref iter));

            prepend(out iter);
            set_valuesv(iter, {Column.KEY, Column.VALUE, Column.DESCRIPTION}, {row.key, row.value, row.description});
        }

        public void delete_row_by_key(string key) {
            var key_down = key.down();

            Gtk.TreeIter iter;
            get_iter_first(out iter);

            do {
                Value val;
                get_value(iter, Column.KEY, out val);
                if (val.get_string().down() == key_down) {
                    remove(ref iter);
                    return;
                }
            } while(iter_next(ref iter));
        }
    }
}