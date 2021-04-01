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

        public string url_encode() {
            var b = new StringBuilder();

            Gtk.TreeIter iter;
            get_iter_first(out iter);

            bool first = true;
            do {
                if (!first) b.append_c('&');
                first = false;

                Value key;
                get_value(iter, Column.KEY, out key);
                Value value;
                get_value(iter, Column.VALUE, out value);

                b.append(Soup.URI.encode(key.get_string(), null));
                b.append_c('=');
                b.append(Soup.URI.encode(value.get_string(), null));
            } while(iter_next(ref iter));

            return b.str;
        }

        public delegate void KeyValueDelegate(string key, string value);

        public void foreach(KeyValueDelegate del) {
            Gtk.TreeIter iter;
            get_iter_first(out iter);

            do {
                Value key;
                get_value(iter, Column.KEY, out key);
                Value value;
                get_value(iter, Column.VALUE, out value);

                del(key.get_string(), value.get_string());
            } while(iter_next(ref iter));
        }
    }
}