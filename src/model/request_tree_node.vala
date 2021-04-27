/* request_tree_node.vala
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
        public string id { get; set; }
        public string? parent_id { get; set; }
        public weak RequestTreeNode? parent { get; set; }
        //  public weak CollectionModel? collection { get; set; }
        public FolderModel? folder { get; set; }
        public Request? request { get; set; }
        public bool is_folder { 
            get { return folder != null; }
        }
        public string name {
            get { return is_folder ? folder.name : request.name; }
        }
        // ListStore of RequestTreeNode's
        //  public ListStore children { get; set; default = new ListStore(typeof(RequestTreeNode)); }
        public Gee.List<RequestTreeNode> children { get; default = new Gee.ArrayList<RequestTreeNode>(); }

        public RequestTreeNode(string id, string? parent_id, FolderModel? folder, Request? request) {
            assert(folder != null || request != null);

            this.id = id;
            this.parent_id = parent_id;
            this.folder = folder;
            this.request = request;
        }

        public void add_child(RequestTreeNode node) {
            assert(is_folder);
            node.parent = this;
            children.add(node);
        }

        private static RequestTreeNode decode_row(Db.RequestNodeRow row) throws Error {
            FolderModel? folder = null;
            Request? request = null;
            if (row.folder_json != null) {
                folder = FolderModel.from_row(row);
            } else {
                request = Request.from_row(row);
            }
            return new RequestTreeNode(row.id, row.parent_id, folder, request);
        }

        // Creates a tree of nodes.
        // Assumes that rows are ordered by parent id, with nulls first.
        public static Gee.List<RequestTreeNode> from_rows(Gee.List<Db.RequestNodeRow> rows) throws Error {
            var lookup = new Gee.HashMap<string, RequestTreeNode>();

            foreach (var row in rows) {
                var node = decode_row(row);
                lookup.set(node.id, node);
            }
            
            var root = new Gee.ArrayList<RequestTreeNode>();
            foreach (var entry in lookup.entries) {
                var parent = lookup.get(entry.value.parent_id);
                if (parent != null) {
                    entry.value.parent = parent;
                    entry.value.parent.children.add(entry.value);
                } else {
                    root.add(entry.value);
                }
            }

            return root;
        }
    }
}