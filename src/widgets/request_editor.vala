/* request_editor.vala
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

	[GtkTemplate(ui = "/me/blq/Repose/ui/RequestEditor.ui")]
    public class RequestEditor : Gtk.Box {

        private Models.RootState root_state;
        private Models.Request request;

        [GtkChild] private Gtk.Stack request_response_stack;
        [GtkChild] private Gtk.Entry request_name_entry;
        //  [GtkChild] private Gtk.ComboBox request_method_combo;
        [GtkChild] private Gtk.ComboBoxText request_method_combo;
        [GtkChild] private Gtk.Entry url_entry;
        //  [GtkChild] private Gtk.Button send_button;
        //  [GtkChild] private Gtk.Button save_button;

        private RequestContainer request_container;
        private ResponseContainer response_container;

        public RequestEditor(Models.RootState root_state, Models.Request request) {
            this.root_state = root_state;
            this.request = request;

            request_container = new RequestContainer();
            response_container = new ResponseContainer(request.response);

            request_response_stack.add_titled(request_container, "request", "Request");
            request_response_stack.add_titled(response_container, "response", "Response");

            // Bindings

            request.bind_property("name", request_name_entry, "text", BindingFlags.BIDIRECTIONAL);
            request.bind_property("url", url_entry, "text", BindingFlags.BIDIRECTIONAL);
            request.bind_property("method", request_method_combo, "active-id", BindingFlags.DEFAULT);
            request_method_combo.changed.connect(() => {
                request.method = request_method_combo.get_active_text();
            });
        }

        [GtkCallback]
        private void on_save_pressed(Gtk.Button btn) {}

        [GtkCallback]
        private async void on_send_pressed(Gtk.Button btn) {
            message("Executing request: %s", request.name);
            request_response_stack.set_visible_child(response_container);
            yield root_state.execute_active_request();
        }
        
        [GtkCallback]
        private void on_request_name_changed() {}
    }
}
