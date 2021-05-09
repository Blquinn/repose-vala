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
            active_requests.append(req);
            active_request = req;
        }

        public void save_request(Request req) {
            debug("Saving request: %s", req.id);

            request_tree.update_node(req, req.persisted, false);

            GLib.Idle.add(() => {
                try {
                    if (req.persisted) { 
                        request_dao.update_request_node(req.to_row());
                    } else {
                        request_dao.insert_request_node(req.to_row());
                    }
                    req.persisted = true;
                    debug("Successfully saved request: %s", req.id);
                } catch (Error e) {
                    warning("Failed to update request: %s", e.message);
                }

                return false;
            });
        }
        
        public void create_folder(FolderModel folder) {
            debug("Creating folder: %s", folder.id);

            request_tree.update_node(folder, false, true);

            GLib.Idle.add(() => {
                try {
                    request_dao.insert_request_node(folder.to_row());
                    debug("Successfully saved folder: %s", folder.id);
                } catch (Error e) {
                    warning("Failed to save folder: %s", e.message);
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

        public void load_request_by_id(string id) throws Error {
            var n = active_requests.get_n_items();
            for (int i = 0; i < n; i++) {
                var ar = (Models.Request) active_requests.get_item(i);
                if (ar.id == id) {
                    active_request = ar;
                    return;
                }
            }
            var row = request_dao.get_request_by_id(id);
            var req = Models.Request.from_row(row);
            active_requests.append(req);
            active_request = req;
        }
    }
}
