/* base_tree_node.vala
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
    // BaseTreeNode is the base model for objects that can be inserted & updated
    // into the request tree.
    public abstract class BaseTreeNode : Object {
        public string id { get; set; }
        public string name { get; set; }
        public string? parent_id { get; set; }

        protected BaseTreeNode(string id, string name, string? parent_id) {
            this.id = id;
            this.name = name;
            this.parent_id = parent_id;
        }
    }
}
