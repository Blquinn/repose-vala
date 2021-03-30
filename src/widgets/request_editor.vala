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

        [GtkChild] private Gtk.Stack request_response_stack;
        [GtkChild] private Gtk.Entry request_name_entry;
        //  [GtkChild] private Gtk.ComboBox request_method_combo;
        [GtkChild] private Gtk.ComboBoxText request_method_combo;
        [GtkChild] private Gtk.Entry url_entry;
        //  [GtkChild] private Gtk.Button send_button;
        //  [GtkChild] private Gtk.Button save_button;

        private RequestContainer request_container;
        private ResponseContainer response_container;

        private Binding name_binding;
        private Binding url_binding;
        private Binding method_binding;

        public RequestEditor(Models.RootState root_state) {
            this.root_state = root_state;

            request_container = new RequestContainer(root_state);
            response_container = new ResponseContainer(root_state);

            request_response_stack.add_titled(request_container, "request", "Request");
            request_response_stack.add_titled(response_container, "response", "Response");


            // Bindings

            bind_request();

            root_state.active_request_changed.connect(on_active_request_changed);
            request_method_combo.changed.connect(on_request_method_combo_changed);
            url_entry.changed.connect(on_url_entry_changed);
        }

        private void on_active_request_changed() {
            bind_request();
        }

        private void bind_request() {
            if (name_binding != null) name_binding.unbind();
            if (url_binding != null) url_binding.unbind();
            if (method_binding != null) method_binding.unbind();

            var request = root_state.active_request;

            request_name_entry.text = request.name;
            url_entry.text = request.url;
            request_method_combo.active_id = request.method;

            name_binding = request.bind_property("name", request_name_entry, "text", BindingFlags.BIDIRECTIONAL);
            //  name_binding = request_name_entry.bind_property("text", request, "name");
            url_binding = request.bind_property("url", url_entry, "text", BindingFlags.BIDIRECTIONAL);
            method_binding = request.bind_property("method", request_method_combo, "active-id", BindingFlags.DEFAULT);
        }

        private void on_request_method_combo_changed() {
            var request = root_state.active_request;
            request.method = request_method_combo.get_active_text();
        }

        [GtkCallback]
        private void on_save_pressed(Gtk.Button btn) {}

        [GtkCallback]
        private async void on_send_pressed(Gtk.Button btn) {
            var request = root_state.active_request;

            if (request.url == "") { // TODO: Error states?
                url_entry.get_style_context().add_class("error");
                return;
            }

            var uri = new Soup.URI(request.url);
            if (uri == null || uri.scheme == "" || uri.host == "") {
                url_entry.get_style_context().add_class("error");
                return;
            }

            message("Executing request: %s", request.name);
            request_response_stack.set_visible_child(response_container);
            yield root_state.execute_active_request();
        }
        
        [GtkCallback]
        private void on_request_name_changed() {}

        private void on_url_entry_changed() {
            // Clear error class.
            url_entry.get_style_context().remove_class("error");
        }
    }
}
