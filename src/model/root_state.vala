/* root_state.vala
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

using Repose;

namespace Repose.Models {
    public class RootState : GLib.Object {

        private Services.HttpClient http_client;

        public signal void active_request_changed();
        private Request _active_request = null;
        public Request active_request { 
            get { return _active_request; }
            set {
                _active_request = value;
                active_request_changed();
            }
        }

        public ListStore active_requests { get; default = new ListStore(typeof(Request)); }

        public RootState() {
            http_client = new Services.HttpClient();
        }

        public void add_new_request() {
            var req = Request.empty();
            active_requests.append(req);
            active_request = req;
        }

        public async void execute_active_request() {
            var req = active_request;
            yield http_client.do_request(req, req.response);
        }
    }
}
