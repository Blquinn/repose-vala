/* folder_dialog.vala
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

	[GtkTemplate(ui = "/me/blq/Repose/ui/FolderDialog.ui")]
    public abstract class FolderDialog : Gtk.Dialog {
        [GtkChild] protected unowned Gtk.TreeView folder_tree;
        [GtkChild] protected unowned Gtk.Label name_label;
        [GtkChild] protected unowned Gtk.Entry name_entry;
        [GtkChild] protected unowned Gtk.Button ok_button;

        protected Gtk.TreeModelFilter folder_tree_model;
        protected Models.RootState root_state;
        private Binding name_binding;

        protected FolderDialog(Models.RootState root_state) {
            this.root_state = root_state;
            var req = root_state.active_request;

            // Only show folders.
            folder_tree_model = new Gtk.TreeModelFilter(root_state.request_tree, null);
            folder_tree_model.set_visible_func((model, iter) => {
                Value val;
                model.get_value(iter, Models.RequestTreeStore.Columns.IS_FOLDER, out val);
                return val.get_boolean();
            });
            folder_tree.model = folder_tree_model;
            folder_tree.expand_all();
            
            // Bind request.

            name_entry.text = req.name;
            name_binding = req.bind_property("name", name_entry, "text", BindingFlags.BIDIRECTIONAL);
        }

        ~FolderDialog() {
            name_binding.unbind();
        }

        [GtkCallback] protected abstract void on_ok_button_clicked();

        [GtkCallback]
        private void on_cancel_button_clicked() {
            close();
        }

        [GtkCallback]
        private void on_save_root_folder_button_clicked() {
            debug("Deselecting folder rows.");
            folder_tree.get_selection().unselect_all();
        }
    }
}