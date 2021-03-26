namespace Repose.Widgets {

    using Repose;

	[GtkTemplate(ui = "/me/blq/Repose/ui/ActiveRequestTab.ui")]
    public class ActiveRequestTab : Gtk.Box {
        [GtkChild]
        private Gtk.Label request_name_label;

        private Models.Request request;

        public ActiveRequestTab(Models.Request request) {
            this.request = request;

            request.bind_property("name", request_name_label, "label");
        }

        [GtkCallback]
        private void close_button_clicked(Gtk.Button btn) {
        }
    }
}