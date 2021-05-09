/* folder_model.vala
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
    public class FolderModel : BaseTreeNode {
        public FolderModel(string id, string name, string? parent_id) {
            base(id, name, parent_id);
        }

        public static FolderModel from_row(Db.RequestNodeRow row) throws Error {
            assert(row.folder_json != null);
            var dto = (Db.FolderDto) Json.gobject_from_data(typeof(Db.FolderDto), row.folder_json);
            return new FolderModel(row.id, dto.name, row.parent_id);
        }

        public Db.FolderDto to_dto() {
            return new Db.FolderDto(id, parent_id, name);
        }

        public Db.RequestNodeRow to_row() throws Error {
            return new Db.RequestNodeRow(id, parent_id, Json.gobject_to_data(this.to_dto(), null), null);
        }
    }
}
