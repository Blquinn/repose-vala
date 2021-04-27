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
        private Services.RequestDao request_dao;

        public signal void active_request_changed();
        private Request _active_request = null;
        public Request active_request { 
            get { return _active_request; }
            set {
                _active_request = value;
                active_request_changed();
            }
        }

        public bool is_request_list_open { get; set; default = false; }
        //  public ListStore collections { get; set; default = new ListStore(typeof(CollectionModel)); }
        public ListStore active_requests { get; default = new ListStore(typeof(Request)); }
        public Models.RequestTreeStore request_tree { get; default = new Models.RequestTreeStore(); }

        public RootState(Services.RequestDao request_dao) {
            http_client = new Services.HttpClient();
            active_request = Request.empty();
            this.request_dao = request_dao;
        }

        public void add_new_request() {
            var req = Request.empty();
            debug("Creating request: %s", req.id);
            GLib.Idle.add(() => {
                try {
                    request_dao.insert_request(req.to_row());
                } catch (Error e) {
                    warning("Failed to create request: %s", e.message);
                    return false;
                }

                debug("Successfully created request: %s", req.id);
                active_requests.append(req);
                active_request = req;
                return false;
            });
        }

        public void save_request(Request req) {
            debug("Saving request: %s", req.id);
            GLib.Idle.add(() => {
                try {
                    request_dao.update_request(req.to_row());
                    debug("Successfully saved request: %s", req.id);
                } catch (Error e) {
                    warning("Failed to update request: %s", e.message);
                }

                return false;
            });
        }

        public void load_requests() {
            debug("Loading requests");
            GLib.Idle.add(() => {
                try {
                    var requests = request_dao.get_requests();
                    var nodes = Models.RequestTreeNode.from_rows(requests);
                    request_tree.populate_store(nodes);
                    debug("Successfully loaded %d requests.", requests.size);
                } catch (Error e) {
                    warning("Failed to load requests: %s", e.message);
                }

                return false;
            });
        }

        public async void execute_active_request() {
            var req = active_request;
            yield http_client.do_request(req, req.response);
        }
    }
}
