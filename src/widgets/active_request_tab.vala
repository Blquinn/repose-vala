/* active_request_tab.vala
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

	[GtkTemplate(ui = "/me/blq/Repose/ui/ActiveRequestTab.ui")]
    public class ActiveRequestTab : Gtk.Box {
        [GtkChild]
        private Gtk.Label request_name_label;

        private Models.RootState root_state;
        private Models.Request request;

        public ActiveRequestTab(Models.RootState root_state, Models.Request request) {
            this.root_state = root_state;
            this.request = request;

            //  if (request.name == "") request_name_label.label = "New Request";
            //  request.bind_property("name", request_name_label, "label", BindingFlags.DEFAULT, map_request_name);
            request.notify.connect(on_request_notify);
            set_request_name_label();
        }

        private void on_request_notify(ParamSpec spec) {
            if (!(spec.name == "name" || spec.name == "url")) return;

            set_request_name_label();
        }

        private void set_request_name_label() {
            var tooltip = "%s - %s".printf(request.method,
                request.url == "" ? "\"\"" : request.url);

            tooltip_text = tooltip;

            if (request.name != "") {
                request_name_label.label = request.name;
                return;
            }

            if (request.url != "") {
                request_name_label.label = tooltip_text;
                return;
            }

            request_name_label.label = "New Request";
        }

        [GtkCallback]
        private void close_button_clicked(Gtk.Button btn) {
            uint pos;
            var state = root_state;
            var reqs = state.active_requests;
            if (reqs.find(request, out pos)) {
                var was_active = reqs.get_item(pos) == state.active_request;
                reqs.remove(pos);

                if (was_active) {
                    var len = reqs.get_n_items();
                    if (len > 0) {
                        state.active_request = (Models.Request) reqs.get_item(0);
                    } else {
                        state.active_request = null;
                    }
                }
            }
        }
    }
}