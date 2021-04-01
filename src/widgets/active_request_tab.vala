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
            if (root_state.active_requests.find(request, out pos)) {
                root_state.active_requests.remove(pos);
            }
        }
    }
}