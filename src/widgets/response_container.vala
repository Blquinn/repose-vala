/* response_container.vala
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
using Repose.Utils;

namespace Repose.Widgets {

	[GtkTemplate(ui = "/me/blq/Repose/ui/ResponseContainer.ui")]
    public class ResponseContainer : Gtk.Overlay {
        //  [GtkChild] private Gtk.PopoverMenu response_menu_popover;
        //  [GtkChild] private Gtk.AccelLabel response_menu_toggle_filter;
        [GtkChild] private Gtk.Label response_status_label;
        [GtkChild] private Gtk.Label response_time_label;
        [GtkChild] private Gtk.Label response_size_label;
        //  [GtkChild] private Gtk.Notebook response_notebook;
        [GtkChild] private Gtk.TextView response_headers_text;
        //  [GtkChild] private Gtk.SearchBar response_filter_search_bar;
        //  [GtkChild] private Gtk.SearchEntry response_filter_search_entry;
        [GtkChild] private Gtk.SourceView response_text;
        [GtkChild] private Gtk.TextView response_text_raw;
        //  [GtkChild] private Gtk.ScrolledWindow response_webview_scroll_window;
        //  [GtkChild] private Gtk.MenuButton response_menu_button;
        [GtkChild] private Gtk.Spinner response_loading_spinner;

        private Gtk.SourceStyleSchemeManager style_manager;
        private Gtk.SourceLanguageManager language_manager;
        private Gtk.SourceBuffer response_text_buffer;

        private Models.Response response;

        public ResponseContainer(Models.Response response) {
            this.response = response;

            style_manager = new Gtk.SourceStyleSchemeManager();
            response_text_buffer = (Gtk.SourceBuffer)response_text.buffer;
            response_text_buffer.set_style_scheme(style_manager.get_scheme("kate"));

            language_manager = new Gtk.SourceLanguageManager();
            var lang = language_manager.get_language("text-plain");
            response_text_buffer.set_language(lang);

            // Bindings

            response.response_received.connect(on_response_received);
            response.request.bind_property("request_running", response_loading_spinner, "active", BindingFlags.DEFAULT);
            response.request.bind_property("request_running", response_loading_spinner, "visible", BindingFlags.DEFAULT);
        }

        private void on_response_received() {
            response_status_label.set_text("Status: %u".printf(response.status_code));
            response_size_label.set_text("Size: %s".printf(Humanize.bytes(response.body_length)));
            response_time_label.set_text("Time: %s".printf(Humanize.timespan(response.response_time)));
            response_text_raw.buffer.text = response.body;
            set_headers_text();

            // Prettify response
            set_pretty_response();
        }

        private void set_pretty_response() {
            if (response.content_type == null) return;

            string lang_id = "text-plain";
            string ct = response.content_type.split(";")[0];
            switch (ct) {
            case "application/json":
                lang_id = "json";
                break;
            case "application/xml":
                lang_id = "xml";
                break;
            case "text/xml":
                lang_id = "xml";
                break;
            case "text/html":
                lang_id = "xml";
                break;
            case "application/javascript":
                lang_id = "js";
                break;
            }

            var lang = language_manager.get_language(lang_id);
            response_text_buffer.set_language(lang);

            response_text_buffer.set_text(response.body);
        }

        private void set_headers_text() {
            var buf = response_headers_text.buffer;
            buf.text = "";

            Gtk.TextIter iter;
            buf.get_start_iter(out iter);

            for (uint i = 0; i < response.headers.length; i++) {
                unowned var h = response.headers.index(i);

                buf.insert_markup(ref iter, "<b>%s:</b> %s\n".printf(h.key, h.value), -1);
            }
        }

        [GtkCallback]
        private void on_response_filter_changed() {}

        [GtkCallback]
        private void populate_response_text_context_menu(Gtk.Menu popup) {}
    }

}