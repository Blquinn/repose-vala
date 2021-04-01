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
    public class ResponseContainer : Gtk.Box {
        private const size_t MAX_BODY_SIZE = 10<<20; // 10 MiB
        private static string MAX_BODY_SIZE_HR = Utils.Humanize.bytes(MAX_BODY_SIZE);
        private const size_t MAX_LINE_LEN = 5000;

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
        [GtkChild] private Gtk.Box request_loading_overlay;

        private Gtk.SourceStyleSchemeManager style_manager;
        private Gtk.SourceLanguageManager language_manager;
        private Gtk.SourceBuffer response_text_buffer;

        private Models.RootState root_state;

        private Binding loading_spinner_binding;
        private Binding loading_overlay_binding;

        private Binding status_code_binding;
        private Binding body_length_binding;
        private Binding response_time_binding;

        public ResponseContainer(Models.RootState root_state) {
            this.root_state = root_state;

            style_manager = new Gtk.SourceStyleSchemeManager();
            response_text_buffer = (Gtk.SourceBuffer)response_text.buffer;
            //  response.body = response_text_buffer;
            response_text_buffer.set_style_scheme(style_manager.get_scheme("kate"));

            language_manager = new Gtk.SourceLanguageManager();
            var lang = language_manager.get_language("text-plain");
            response_text_buffer.set_language(lang);

            // Bindings
            bind_request();

            root_state.active_request_changed.connect(on_active_request_changed);
        }

        private async void on_active_request_changed() {
            bind_request();
            set_headers_text();
            yield load_response_file(root_state.active_request.response);
        }

        private void bind_request() {
            if (loading_spinner_binding != null) loading_spinner_binding.unbind();
            if (loading_overlay_binding != null) loading_overlay_binding.unbind();
            if (status_code_binding != null) status_code_binding.unbind();
            if (body_length_binding != null) body_length_binding.unbind();
            if (response_time_binding != null) response_time_binding.unbind();

            var response = root_state.active_request.response;
            loading_spinner_binding = response.request.bind_property("request_running", response_loading_spinner, "active");
            loading_overlay_binding = response.request.bind_property("request_running", request_loading_overlay, "visible");
            response.response_received.connect(on_response_received);

            status_code_binding = response.bind_property("status_code", response_status_label, "label", 
                BindingFlags.DEFAULT,
                (a, from, ref to) => {
                    to.set_string(format_status_code(from.get_uint()));
                    return true;
                });
            body_length_binding = response.bind_property("body_length", response_size_label, "label", BindingFlags.DEFAULT,
                (a, from, ref to) => {
                    to.set_string(format_body_length(from.get_int64()));
                    return true;
                });
            response_time_binding = response.bind_property("response_time", response_time_label, "label", BindingFlags.DEFAULT,
                (a, from, ref to) => {
                    to.set_string(format_response_time((TimeSpan)from.get_int64()));
                    return true;
                });
            response_status_label.set_text(format_status_code(response.status_code));
            response_size_label.set_text(format_body_length(response.body_length));
            response_time_label.set_text(format_response_time(response.response_time));
        }

        private string format_status_code(uint status_code) {
            string fmt_str = "Status: ";
            if (status_code == 0) return fmt_str + "-";
            return fmt_str + status_code.to_string();
        }
        
        private string format_body_length(int64 bl) {
            string fmt_str = "Size: ";
            if (bl < 0) return fmt_str + "-";
            return fmt_str + Humanize.bytes((size_t) bl);
        }
        
        private string format_response_time(TimeSpan rt) {
            string fmt_str = "Time: ";
            if (rt < 0) return fmt_str + "-";
            return fmt_str + Humanize.timespan(rt);
        }

        private async void on_response_received() {
            var response = root_state.active_request.response;
            
            set_headers_text();

            if (response.error_text != "") {
                response_text_buffer.text = response.error_text;
                response_text_raw.buffer.text = response.error_text;
                return;
            }

            // TODO: Load from file.
            yield load_response_file(response);

            // Prettify response
            set_pretty_response();
        }

        // Loads the response file, if it exists, into the response buffers.
        private async void load_response_file(Models.Response response) {
            response_text_buffer.text = "";
            response_text_raw.buffer.text = "";

            if (response.response_file_path != "") {
                message("Loading response data from %s", response.response_file_path);

                var file = File.new_for_path(response.response_file_path);

                InputStream input_stream;
                int64 file_size;
                try {
                    // TODO: For binary, create a hexdump converter.
                    message("Converting response text to UTF-8 from %s", response.text_encoding);

                    var info = yield file.query_info_async("*", 0);
                    file_size = info.get_size();

                    var converter = new CharsetConverter("UTF-8", response.text_encoding);
                    input_stream = new ConverterInputStream(yield file.read_async(), converter);
                } catch (Error e) {
                    message("Faild to read file: %s", e.message);
                    return;
                }

                var raw_buf = response_text_raw.buffer;

                if (file_size > MAX_BODY_SIZE) {
                    raw_buf.text = @"Response size is greater than maximum displayable size of $(MAX_BODY_SIZE_HR)";
                    set_pretty_response();
                    return;
                }

                var body = new Array<uint8>();
                while (true) {
                    try {
                        var bts = yield input_stream.read_bytes_async(4<<10);

                        if (bts.length == 0) break;

                        body.append_vals(bts.get_data(), bts.length);
                    } catch(Error e) {
                        var msg = "Failed to read file stream: %s".printf(e.message);
                        message(msg);
                        raw_buf.text = msg;
                        return;
                    }
                }

                var body_text = (string)body.data;
                //  int max_len = 0;
                bool over_max = false;
                int line_len = 0;
                int iters = 0;
                for (var i = 0; i < body_text.length; i++) {
                    iters++;
                    if (body_text[i] == '\n') {
                        if (line_len > MAX_LINE_LEN) {
                            over_max = true;
                            break;
                        }
                        line_len = 0;
                    } else {
                        line_len++;
                    }
                }

                var wrap_mode = over_max ? Gtk.WrapMode.WORD_CHAR : Gtk.WrapMode.NONE;
                response_text.wrap_mode = wrap_mode;
                response_text_raw.wrap_mode = wrap_mode;

                raw_buf.text = body_text;

                set_pretty_response();
            }
        }

        private void set_pretty_response() {
            var response = root_state.active_request.response;

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
                //  lang_id = "html";
                break;
            case "application/javascript":
                lang_id = "js";
                break;
            }

            var lang = language_manager.get_language(lang_id);
            response_text_buffer.set_language(lang);

            //  response_text_raw.buffer.text;
            switch (lang_id) {
            case "json":
                var raw = response_text_raw.buffer.text;
                try {
                    var root = Json.from_string(raw);
                    var pretty = Json.to_string(root, true);
                    response_text_buffer.set_text(pretty);
                } catch (Error e) {
                    response_text_buffer.set_text(raw);
                }
                break;
            case "xml":
                // TODO: Prettify xml.
                response_text_buffer.set_text(response_text_raw.buffer.text);
                break;
            default:
                response_text_buffer.set_text(response_text_raw.buffer.text);
                break;
            }

        }

        private void set_headers_text() {
            var buf = response_headers_text.buffer;
            buf.text = "";

            Gtk.TextIter iter;
            buf.get_start_iter(out iter);

            var response = root_state.active_request.response;

            for (uint i = 0; i < response.headers.length; i++) {
                unowned var h = response.headers.index(i);

                buf.insert_markup(ref iter, "<b>%s:</b> %s\n".printf(h.key, h.value), -1);
            }
        }

        [GtkCallback]
        private void on_response_filter_changed() {}

        [GtkCallback]
        private void populate_response_text_context_menu(Gtk.Menu menu) {}

        [GtkCallback]
        private void on_cancel_request_button_clicked(Gtk.Button btn) {
            var response = root_state.active_request.response;

            response.request.cancel();
        }
    }

}