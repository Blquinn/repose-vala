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
        public signal void response_received();

        public uint status_code { get; set; default = -1; }
        public TimeSpan response_time { get; set; default = -1; }
        public string content_type { get; set; }
        public Array<ParamRow> headers { get; set; default = new Array<ParamRow>(); }
        // TODO: Properly handle response types.
        public string body { get; set; }
    }
}
