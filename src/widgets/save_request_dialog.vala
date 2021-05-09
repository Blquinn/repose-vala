/* save_request_dialog.vala
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

    public class SaveRequestDialog : Widgets.FolderDialog {
        public SaveRequestDialog(Models.RootState root_state) {
            base(root_state);
        }

        protected override void on_ok_button_clicked() {
            var sel = folder_tree.get_selection();
            Gtk.TreeIter filter_iter;
            var row_is_selected = sel.get_selected(null, out filter_iter);

            var req = root_state.active_request;

            try {
                if (!row_is_selected) {
                    debug("Folder not selected, saving request to root.");
                    root_state.save_request(req);
                    return;
                }

                Gtk.TreeIter iter;
                folder_tree_model.convert_iter_to_child_iter(out iter, filter_iter);
                
                Value val;
                root_state.request_tree.get_value(iter, Models.RequestTreeStore.Columns.ID, out val);
                var folder_id = val.get_string();

                debug("Saving request to folder %s", folder_id);

                req.parent_id = folder_id;
                root_state.save_request(req);
            } finally {
                close();
            }
        }
    }
}
