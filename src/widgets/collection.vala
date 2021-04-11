/* collection.vala
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

	using Repose;

	[GtkTemplate(ui = "/me/blq/Repose/ui/Collection.ui")]
    public class Collection : Gtk.Box {
        //  [GtkChild] private unowned Gtk.TreeStore requests_tree_store;
        //  [GtkChild] private unowned Gtk.EventBox collection_header_event_box;
        [GtkChild] private unowned Gtk.Label collection_name_label;
        [GtkChild] private unowned Gtk.Revealer collection_revealer;
        [GtkChild] private unowned Gtk.TreeView requests_tree_view;
        //  [GtkChild] private unowned Gtk.TreeViewColumn request_name_column;

        private Models.CollectionModel model;

        public Collection(Models.CollectionModel model) {
            this.model = model;

            requests_tree_view.set_model(model.children);

            collection_name_label.label = model.name;
            model.bind_property("name", collection_name_label, "label");
            model.bind_property("expanded", collection_revealer, "reveal_child");
        }

        [GtkCallback]
        private void tree_view_row_activated(Gtk.TreePath path, Gtk.TreeViewColumn column) {
        }
        
        [GtkCallback]
        private bool name_label_pressed(Gdk.EventButton btn) {
            model.expanded = !model.expanded;
            return true;
        }
        /*
    def populate_collection(self):
        it: Gtk.TreeIter = self.requests_tree_store.get_iter_first()
        for node in self.model.nodes:
            self.add_request_node(it, node)

    def add_request_node(self, it: Gtk.TreeIter, node: RequestTreeNode):
        if node.is_folder():
            parent_it = self.requests_tree_store.append(it, [node.folder.name, node.pk, None])
        else:
            parent_it = self.requests_tree_store.append(it, [node.request.name, node.pk, None])

        for child in node.children:
            self.add_request_node(parent_it, child)
 
        */

        //  private void populate_collection() {
            //  Gtk.TreeIter iter;
            //  model.children.get_iter_first(out iter);
            //  do {
            //      Value val;
            //      model.children.get_value(iter, 0, out val);
            //      add_request_node(iter, (Models.RequestTreeNode) val.get_object());
            //  } while(model.children.iter_next(ref iter));
        //  }

        //  private void add_request_node(Gtk.TreeIter iter, Models.RequestTreeNode node) {
        //      Gtk.TreeIter parent_iter;
        //      if (node.is_folder) {
        //          model.children.
        //      } else {

        //      }
        //  }
    }
}
