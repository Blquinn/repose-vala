/* request_row.vala
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

namespace Repose.Models.Db {
    public class RequestDto : Object {
        public string id { get; set; }
        public string? parent_id { get; set; }
        public string name { get; set; }
        public string url { get; set; }
        public string method { get; set; }

        public RequestDto(string id, string? parent_id, string name, string url, string method) {
            this.id = id;
            this.parent_id = parent_id;
            this.name = name;
            this.url = url;
            this.method = method;
        }
    }
    
    public class FolderDto : Object {
        public string id { get; set; }
        public string? parent_id { get; set; }
        public string name { get; set; }

        public FolderDto(string id, string? parent_id, string name) {
            this.id = id;
            this.parent_id = parent_id;
            this.name = name;
        }
    }

    public class RequestNodeRow {
        public string id;
        public string? parent_id;
        public string? folder_json;
        public string? request_json;

        public RequestNodeRow(string id, string? parent_id, string? folder_json, string? request_json) {
            this.id = id;
            this.parent_id = parent_id;
            this.folder_json = folder_json;
            this.request_json = request_json;
        }

        public string to_string() {
            return "RequestNodeRow(id=" + null_str(id) + ", parent_id=" + null_str(parent_id) + 
                ", folder_json=" + null_str(folder_json) + ", request_json=" + null_str(request_json) + ")";
        }

        private string null_str(string? str) {
            return str == null ? "null" : str;
        }
    }
}
