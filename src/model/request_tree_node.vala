
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

    public class RequestTreeNode : Object {
        public string pk { get; set; }
        public weak RequestTreeNode? parent { get; set; }
        public weak CollectionModel? collection { get; set; }
        public FolderModel? folder { get; set; }
        public Request? request { get; set; }
        public bool is_folder { 
            get { return folder != null; }
        }
        public string name {
            get { return is_folder ? folder.name : request.name; }
        }
        // ListStore of RequestTreeNode's
        public ListStore children { get; set; default = new ListStore(typeof(RequestTreeNode)); }

        public RequestTreeNode(FolderModel? folder, Request? request) {
            assert(folder != null || request != null);

            this.folder = folder;
            this.request = request;
        }

        public void add_child(RequestTreeNode node) {
            assert(is_folder);
            node.parent = this;
            children.append(node);
        }

        public void remove_child(RequestTreeNode node) {
            uint pos;
            if (children.find(node, out pos)) children.remove(pos);
        }
    }
}