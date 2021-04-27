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
    public class RequestTreeStore : Gtk.TreeStore {

        enum Columns { NAME, ID, IS_FOLDER }

        public RequestTreeStore() {
            set_column_types({typeof(string), typeof(string), typeof(bool)});
        }

        public void populate_store(Gee.List<Models.RequestTreeNode> nodes) {
            Gtk.TreeIter iter;
            get_iter_first(out iter);
            _populate(nodes, iter, null);
        }

        private void _populate(Gee.List<Models.RequestTreeNode> nodes, Gtk.TreeIter iter, Gtk.TreeIter? parent) {
            foreach (var node in nodes) {
                append(out iter, parent);

                var name = node.name == "" ? "New Request" : node.name;

                set(iter, 
                    Columns.NAME, name, 
                    Columns.ID, node.id, 
                    Columns.IS_FOLDER, node.is_folder);

                _populate(node.children, iter, iter);
            }
        }
    }
}
