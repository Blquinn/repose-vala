/* response.vala
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
    public class Response : Object {
        public const string BINARY_BODY = "__BINARY__";

        public enum SearchMode { TEXT, REGEX }
        public enum FilterMode { TEXT, REGEX, GLOB, PATH }

        public signal void response_received();

        public uint status_code { get; set; default = 0; }
        public TimeSpan response_time { get; set; default = -1; }
        public string content_type { get; set; }
        public string text_encoding { get; set; }
        public Array<ParamRow> headers { get; set; default = new Array<ParamRow>(); }
        public string error_text { get; set; }
        public string response_file_path { get; set; default = ""; }
        public int64 body_length { get; set; default = -1; }

        public bool filter_expanded { get; set; default = false; }
        public string search_text { get; set; default = ""; }
        public string filter_text { get; set; default = ""; }
        public SearchMode search_mode { get; set; default = SearchMode.TEXT; }
        public FilterMode filter_mode { get; set; default = FilterMode.TEXT; }

        public weak Request request { get; set; }

        public Response(Request req) {
            this.request = req;
        }
    }
}
