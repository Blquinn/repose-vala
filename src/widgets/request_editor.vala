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

        [GtkChild] private unowned Gtk.Stack request_response_stack;
        [GtkChild] private unowned Gtk.Entry request_name_entry;
        [GtkChild] private unowned Gtk.ComboBoxText request_method_combo;
        [GtkChild] private unowned Gtk.Entry request_method_combo_entry;
        [GtkChild] private unowned Gtk.Entry url_entry;
        [GtkChild] private unowned Gtk.Button send_button;
        //  [GtkChild] private unowned Gtk.Button save_button;

        private RequestContainer request_container;
        private ResponseContainer response_container;

        private Binding name_binding;
        private Binding url_binding;
        private Binding method_binding;
        private Binding active_tab_binding;

        public RequestEditor(Models.RootState root_state) {
            this.root_state = root_state;

            request_container = new RequestContainer(root_state);
            response_container = new ResponseContainer(root_state);

            request_response_stack.add_titled(request_container, "request", "Request");
            request_response_stack.add_titled(response_container, "response", "Response");

            // Bindings

            bind_request();

            root_state.active_request_changed.connect(on_active_request_changed);
        }
        
        [GtkCallback]
        private bool on_key_press_event(Gdk.EventKey key) {
            if ((key.state & Gdk.ModifierType.CONTROL_MASK) == 0) return true;

            switch (key.keyval) {
            case Gdk.Key.Return:
                on_control_enter_pressed();
                return false;
            case Gdk.Key.space:
                on_control_space_pressed();
                return false;
            default:
                return true;
            }
        }

        private void on_control_enter_pressed() {
            debug("Control-Enter pressed.");
            send_button.clicked();
        }

        private void on_control_space_pressed() {
            debug("Control-Space pressed.");

            root_state.active_request.active_tab = 
                root_state.active_request.active_tab == Models.Request.Tab.REQUEST 
                    ? Models.Request.Tab.RESPONSE 
                    : Models.Request.Tab.REQUEST;

            debug("Active tab now %s", root_state.active_request.active_tab.to_string());
        }

        private void on_active_request_changed() {
            bind_request();
        }

        private void bind_request() {
            if (name_binding != null) name_binding.unbind();
            if (url_binding != null) url_binding.unbind();
            if (method_binding != null) method_binding.unbind();
            if (active_tab_binding != null) active_tab_binding.unbind();

            var request = root_state.active_request;
            if (request == null) return;

            request_name_entry.text = request.name;
            url_entry.text = request.url;
            request_method_combo_entry.text = request.method;

            // Disable animation while changing stack via state change.
            var trans = request_response_stack.transition_type;
            request_response_stack.transition_type = Gtk.StackTransitionType.NONE;
            if (request.active_tab == Models.Request.Tab.REQUEST) {
                request_response_stack.visible_child = request_container;
            } else {
                request_response_stack.visible_child = response_container;
            }
            request_response_stack.transition_type = trans;

            name_binding = request.bind_property("name", request_name_entry, "text", BindingFlags.BIDIRECTIONAL);
            url_binding = request.bind_property("url", url_entry, "text", BindingFlags.BIDIRECTIONAL);
            method_binding = request.bind_property("method", request_method_combo_entry, "text", BindingFlags.DEFAULT);
            active_tab_binding = request.bind_property("active_tab", request_response_stack, "visible-child", BindingFlags.DEFAULT, 
                (_, from, ref to) => {
                    if (from.get_enum() == Models.Request.Tab.REQUEST) {
                        to = request_container;
                    } else {
                        to = response_container;
                    }
                    return true;
                });
        }

        public async void send_request() {
            var request = root_state.active_request;

            if (request.url == "") {
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
        private void on_request_response_stack_notify(ParamSpec param) {
            if (param.name != "visible-child") return;

            var req = root_state.active_request;
            if (request_response_stack.visible_child == request_container) {
                req.active_tab = Models.Request.Tab.REQUEST;
            } else {
                req.active_tab = Models.Request.Tab.RESPONSE;
            }
        }

        [GtkCallback]
        private void on_request_method_combo_changed() {
            var request = root_state.active_request;
            request.method = request_method_combo.get_active_text();
        }

        [GtkCallback]
        private void on_save_pressed(Gtk.Button btn) {
            var req = root_state.active_request;
            if (req.persisted) {
                root_state.save_request(req);
                return;
            }

            var diag = new Widgets.SaveRequestDialog(root_state);
            diag.set_transient_for((Gtk.Window) get_toplevel());
            diag.show_all();
        }

        [GtkCallback]
        private void on_save_as_button_clicked() {
            var diag = new Widgets.SaveRequestDialog(root_state);
            diag.set_transient_for((Gtk.Window) get_toplevel());
            diag.show_all();
        }

        [GtkCallback]
        private async void on_send_pressed(Gtk.Button btn) {
            yield send_request();
        }

        [GtkCallback]
        private async void on_url_entry_activate() {
            yield send_request();
        }

        [GtkCallback]
        private void on_request_name_changed() {}

        [GtkCallback]
        private void on_url_entry_changed() {
            url_entry.get_style_context().remove_class("error");
        }
    }
}
