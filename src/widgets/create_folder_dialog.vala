/* create_folder_dialog.vala
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

    public class CreateFolderDialog : Widgets.FolderDialog {
        public CreateFolderDialog(Models.RootState root_state) {
            base(root_state);

            title = _("Create New Folder.");
            name_label.label = _("Folder Name:");
            ok_button.label = _("Create");
        }

        protected override void on_ok_button_clicked() {
            var sel = folder_tree.get_selection();
            Gtk.TreeIter filter_iter;
            var row_is_selected = sel.get_selected(null, out filter_iter);

            var folder = new Models.FolderModel(Uuid.string_random(), name_entry.text, null);

            try {
                if (!row_is_selected) {
                    debug("Folder not selected, saving folder to root.");

                    //  root_state.save_request(req);
                    root_state.create_folder(folder);
                    return;
                }

                Gtk.TreeIter parent_iter;
                folder_tree_model.convert_iter_to_child_iter(out parent_iter, filter_iter);
                
                Value val;
                root_state.request_tree.get_value(parent_iter, Models.RequestTreeStore.Columns.ID, out val);
                var parent_folder_id = val.get_string();

                folder.parent_id = parent_folder_id;

                debug("Saving new folder to parent folder %s", parent_folder_id);

                root_state.create_folder(folder);
            } finally {
                close();
            }
        }
    }
}
