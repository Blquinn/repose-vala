namespace Repose.Models {
    public class CollectionModel : Object {
        enum Columns { NAME, PK, PIXBUF }

        public string name { get; set; }
        public Gtk.TreeStore children { 
            get; set; 
            //  default = new Gtk.TreeStore(1, typeof(RequestTreeNode));
            default = new Gtk.TreeStore(3, typeof(string), typeof(string), typeof(Gdk.Pixbuf));
        }
        public bool expanded { get; set; default = false; }

        public void populate_collection(RequestTreeNode[] nodes) {
            //  Gtk.TreeIter iter;
            //  children.get_iter_first(out iter);
            foreach (var node in nodes) {
                add_child(null, node);
            }
        }

        public void add_child(Gtk.TreeIter? parent, RequestTreeNode node) {
            node.collection = this;

            Gtk.TreeIter iter;
            children.append(out iter, parent);
            children.set(iter, Columns.NAME, node.name, Columns.PK, "", Columns.PIXBUF, null);

            for (int i = 0; i < node.children.get_n_items(); i++) {
                add_child(iter, (RequestTreeNode) node.children.get_item(i));
            }
        }
    }
}