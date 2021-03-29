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

            if (request.name == "") request_name_label.label = "New Request";
            request.bind_property("name", request_name_label, "label", BindingFlags.DEFAULT, 
                (b, from, ref to) => { 
                    var name = from.get_string() == "" ? "New Request" : from.get_string();
                    to.set_string(name);
                    return true;
                });
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