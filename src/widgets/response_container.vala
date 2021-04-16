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

        //  [GtkChild] private unowned Gtk.PopoverMenu response_menu_popover;
        //  [GtkChild] private unowned Gtk.AccelLabel response_menu_toggle_filter;
        [GtkChild] private unowned Gtk.Label response_status_label;
        [GtkChild] private unowned Gtk.Label response_time_label;
        [GtkChild] private unowned Gtk.Label response_size_label;
        //  [GtkChild] private unowned Gtk.Notebook response_notebook;
        [GtkChild] private unowned Gtk.TextView response_headers_text;
        [GtkChild] private unowned Gtk.Revealer response_filter_search_bar;
        [GtkChild] private unowned Gtk.SearchEntry response_filter_entry;
        [GtkChild] private unowned Gtk.SearchEntry response_search_entry;
        [GtkChild] private unowned Gtk.SourceView response_text;
        [GtkChild] private unowned Gtk.TextView response_text_raw;
        //  [GtkChild] private unowned Gtk.ScrolledWindow response_webview_scroll_window;
        //  [GtkChild] private unowned Gtk.MenuButton response_menu_button;
        [GtkChild] private unowned Gtk.Spinner response_loading_spinner;
        [GtkChild] private unowned Gtk.Box request_loading_overlay;

        //  [GtkChild] private unowned Gtk.Button search_find_previous_button;
        //  [GtkChild] private unowned Gtk.Button search_find_next_button;

        [GtkChild] private unowned Gtk.ToggleButton search_use_regex_button;
        [GtkChild] private unowned Gtk.ToggleButton search_use_text_button;
        [GtkChild] private unowned Gtk.ToggleButton filter_use_path_filter_button;
        [GtkChild] private unowned Gtk.ToggleButton filter_use_regex_button;
        [GtkChild] private unowned Gtk.ToggleButton filter_use_glob_button;
        [GtkChild] private unowned Gtk.ToggleButton filter_use_text_button;

        private Gtk.SourceStyleSchemeManager style_manager;
        private Gtk.SourceLanguageManager language_manager;
        private Gtk.SourceBuffer response_text_buffer;

        private Gtk.SourceSearchContext search_context;
        private Gtk.TextIter? search_start_iter;
        private Gtk.TextIter? search_end_iter;

        private Models.RootState root_state;

        private Binding loading_spinner_binding;
        private Binding loading_overlay_binding;

        private Binding status_code_binding;
        private Binding body_length_binding;
        private Binding response_time_binding;

        private Binding response_filter_expand_binding;
        private Binding filter_text_binding;
        private Binding search_text_binding;

        // TODO: Fix response_received handler getting called twice and
        // remove this hack.
        private bool loading_response_file = false;

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
            debug("Active request changed.");

            if (root_state.active_request == null) return;

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
            if (response_filter_expand_binding != null) response_filter_expand_binding.unbind();
            if (filter_text_binding != null) filter_text_binding.unbind();
            if (search_text_binding != null) search_text_binding.unbind();

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
            response_filter_expand_binding = response.bind_property("filter_expanded", response_filter_search_bar, "reveal_child", BindingFlags.BIDIRECTIONAL);
            // TODO: Filter text writing into search text?
            filter_text_binding = response.bind_property("search_text", response_search_entry, "text", BindingFlags.BIDIRECTIONAL);
            search_text_binding = response.bind_property("filter_text", response_filter_entry, "text", BindingFlags.BIDIRECTIONAL);
            response.notify.connect((param) => {
                if (param.name == "search_mode")
                    update_search_button();
                else if (param.name == "filter_mode")
                    update_filter_button();
            });

            update_search_button();
            update_filter_button();
            response_search_entry.set_text(response.search_text);
            response_filter_entry.set_text(response.filter_text);
            response_status_label.set_text(format_status_code(response.status_code));
            response_size_label.set_text(format_body_length(response.body_length));
            response_time_label.set_text(format_response_time(response.response_time));
            response_filter_search_bar.reveal_child = response.filter_expanded;
        }

        private void update_search_button() {
            switch (root_state.active_request.response.search_mode) {
            case Models.Response.SearchMode.REGEX:
                search_use_regex_button.active = true;
                break;
            case Models.Response.SearchMode.TEXT:
                search_use_text_button.active = true;
                break;
            }
        }
        
        private void update_filter_button() {
            switch (root_state.active_request.response.filter_mode) {
            case Models.Response.FilterMode.TEXT:
                filter_use_text_button.active = true;
                break;
            case Models.Response.FilterMode.REGEX:
                filter_use_regex_button.active = true;
                break;
            case Models.Response.FilterMode.GLOB:
                filter_use_glob_button.active = true;
                break;
            case Models.Response.FilterMode.PATH:
                filter_use_path_filter_button.active = true;
                break;
            }
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
            debug("Response received.");

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
            if (loading_response_file) return;

            response_text_buffer.text = "";
            response_text_raw.buffer.text = "";

            if (response.response_file_path == "") return;

            loading_response_file = true;
            try {
                debug("Loading response data from %s", response.response_file_path);

                var file = File.new_for_path(response.response_file_path);

                InputStream input_stream;
                int64 file_size;
                try {
                    // TODO: For binary, create a hexdump converter.

                    var info = yield file.query_info_async("*", 0);
                    file_size = info.get_size();

                    input_stream = yield file.read_async();
                    if (!(response.text_encoding == "UTF-8" || response.text_encoding == "ASCII")) {
                        message("Converting response text to UTF-8 from %s", response.text_encoding);
                        var converter = new CharsetConverter("UTF-8", response.text_encoding);
                        input_stream = new ConverterInputStream(yield file.read_async(), converter);
                    }
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

                // Only filter if the filter bar is open and filter is active.
                if (response_filter_search_bar.child_revealed && response_filter_entry.text != "") {
                    // Path filter.

                    if (filter_use_path_filter_button.active) {
                        switch (response.content_type) {
                        case "application/json":
                            debug("Applying json filter");
                            try {
                                var root = Json.from_string(body_text);
                                var filtered = Json.Path.query(response_filter_entry.text, root);
                                body_text = Json.to_string(filtered, true);
                            } catch (Error e) {
                                message("Failed to filter json data: %s", e.message);
                            }
                            break;
                        case "text/xml":
                        case "application/xml":
                        case "text/html":
                            debug("Using XPath filter.");
                            Xml.Doc* doc;
                            Xml.XPath.Object* res;
                            try {
                                if (response.content_type == "text/html") {
                                    doc = Html.Doc.read_doc(body_text, response.request.url, "UTF-8");
                                } else {
                                    doc = Xml.Parser.parse_doc(body_text);
                                }
                                if (doc == null) {
                                    message("Failed to parse xml document.");
                                    break;
                                }

                                var cntx = new Xml.XPath.Context(doc);
                                res = cntx.eval_expression(response_filter_entry.text);
                                if (res == null) {
                                    message("Failed to parse xml path.");
                                    break;
                                }

                                assert(res != null);
                                assert(res->type == Xml.XPath.ObjectType.NODESET);
                                assert(res->nodesetval != null);

                                var new_body = new StringBuilder();
                                for (int i = 0; i < res->nodesetval->length(); i++) {
                                    var node = res->nodesetval->item(i);
                                    var buf = new Xml.Buffer();
                                    buf.node_dump(doc, node, 0, 1);
                                    new_body.append(buf.content());
                                    if (res->nodesetval->length() > 1) new_body.append_c('\n');
                                }
                                
                                body_text = new_body.str;
                            } finally {
                                delete doc;
                                delete res;
                            }
                            break;
                        default:
                            break;
                        }
                    } else if (filter_use_regex_button.active) { // Regex filter.
                        Regex rex;
                        try {
                            rex = new Regex(response_filter_entry.text, RegexCompileFlags.CASELESS);
                        } catch(RegexError e) {
                            message("Failed to compile filter regex: %s", e.message);
                            return;
                        }

                        var new_body = new StringBuilder();
                        foreach (var line in body_text.split("\n")) {
                            if (rex.match(line)) {
                                new_body.append(line);
                                new_body.append_c('\n');
                            }
                        }
                        body_text = new_body.str;
                    } else if (filter_use_glob_button.active) { // Pattern filter
                        var pattern = new PatternSpec(response_filter_entry.text.down());
                        var new_body = new StringBuilder();
                        foreach (var line in body_text.split("\n")) {
                            if (pattern.match_string(line.down())) {
                                new_body.append(line);
                                new_body.append_c('\n');
                            }
                        }
                        body_text = new_body.str;
                    } else { // Text filter
                        var new_body = new StringBuilder();
                        var txt = response_filter_entry.text.down();
                        foreach (var line in body_text.split("\n")) {
                            if (line.down().contains(txt)) {
                                new_body.append(line);
                                new_body.append_c('\n');
                            }
                        }
                        body_text = new_body.str;
                    }
                }

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
            } finally {
                loading_response_file = false;
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
                    string pretty = "";
                    if (root != null) pretty = Json.to_string(root, true);
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
        private async void on_response_search_entry_search_changed() {
            response_search_entry.get_style_context().remove_class("error");

            var search_text = root_state.active_request.response.search_text;
            if (search_text.length < 3) {
                if (search_context != null) {
                    search_context.settings.search_text = "";
                }
                return;
            }

            var settings = new Gtk.SourceSearchSettings();
            settings.search_text = search_text;
            settings.case_sensitive = false;
            settings.regex_enabled = search_use_regex_button.active;
            settings.wrap_around = true;
            search_context = new Gtk.SourceSearchContext(response_text_buffer, settings);
            search_context.highlight = true;
            var rex_err = search_context.get_regex_error();
            if (rex_err != null) {
                message("Failed to compile search regex: %s", rex_err.message);
                response_search_entry.get_style_context().add_class("error");
            }

            response_text_buffer.get_start_iter(out search_start_iter);
            response_text_buffer.get_end_iter(out search_end_iter);

            yield find_next_search_match();
        }

        private async void find_next_search_match() {
            if (search_context == null || search_context.occurrences_count == 0) return;

            try {
                var found = yield search_context.forward_async(search_end_iter, null, out search_start_iter, out search_end_iter, null);
                if (!found) return;
            } catch (Error e) {
                warning("Failed to find next match: %s", e.message);
                return;
            }

            response_text.scroll_to_iter(search_start_iter, 0.1, true, 0.5, 0.5);
        }
        
        private async void find_previous_search_match() {
            if (search_context == null || search_context.occurrences_count == 0) return;

            try {
                var found = yield search_context.backward_async(search_start_iter, null, out search_start_iter, out search_end_iter, null);
                if (!found) return;
            } catch (Error e) {
                warning("Failed to find previous match: %s", e.message);
                return;
            }

            response_text.scroll_to_iter(search_start_iter, 0.1, true, 0.5, 0.5);
        }

        [GtkCallback]
        private async void on_search_find_next_button_clicked() {
            yield find_next_search_match();
        }

        [GtkCallback]
        private async void on_search_find_previous_button_clicked() {
            yield find_previous_search_match();
        }

        [GtkCallback]
        private void populate_response_text_context_menu(Gtk.Menu menu) {
            var menu_item = new Gtk.MenuItem.with_label("Show response filter.");
            weak ResponseContainer self = this;
            menu_item.button_press_event.connect((btn) => {
                self.on_show_response_filter_button_clicked();
                return true;
            });
            menu_item.show_all();
            menu.append(menu_item);
        }

        [GtkCallback]
        private void on_show_response_filter_button_clicked() {
            show_filter_bar();
        }

        private void show_filter_bar() {
            response_filter_search_bar.reveal_child = !response_filter_search_bar.reveal_child;
            if (response_filter_search_bar.reveal_child) {
                response_search_entry.grab_focus();
            }
        }

        [GtkCallback]
        private async void on_close_filter_bar_button_clicked() {
            yield close_filter_bar();
        }

        [GtkCallback]
        private async void on_response_search_entry_stop_search() {
            yield close_filter_bar();
        }
        
        [GtkCallback]
        private async void on_response_filter_entry_stop_search() {
            yield close_filter_bar();
        }

        private async void close_filter_bar() {
            debug("Closing filter bar.");
            // Clear search.
            response_filter_search_bar.reveal_child = false;
            search_context = null;
            if (filter_use_path_filter_button.active) {
                // Reload file to clear filter when we close the filter bar.
                yield load_response_file(root_state.active_request.response);
            }
        }

        [GtkCallback]
        private async void on_response_filter_entry_activate() {
            debug("Response filter entry activated.");
            yield load_response_file(root_state.active_request.response);
        }

        [GtkCallback]
        private async void on_response_search_entry_activate() {
            debug("Response search entry activated.");
            yield find_next_search_match();
        }

        [GtkCallback]
        private async void on_filter_button_clicked() {
            debug("Response filter button clicked.");
            yield load_response_file(root_state.active_request.response);
        }

        [GtkCallback]
        private async void on_response_filter_entry_search_changed() {
            // When the filter is cleared, re-load the response body.
            var filter_text = root_state.active_request.response.filter_text;
            if (filter_text == "") {
                yield load_response_file(root_state.active_request.response);
            }
        }

        [GtkCallback]
        private bool on_response_text_key_press_event(Gdk.EventKey key) {
            if ((key.state & Gdk.ModifierType.CONTROL_MASK) == 0) return true;
            if (key.keyval != Gdk.Key.f) return true;

            show_filter_bar();
            return false;
        }

        [GtkCallback]
        private void on_cancel_request_button_clicked(Gtk.Button btn) {
            var response = root_state.active_request.response;

            response.request.cancel();
        }

        [GtkCallback]
        private void on_search_button_toggled() {
            debug("Search button toggled.");
            var res = root_state.active_request.response;
            if (search_use_regex_button.active) {
                res.search_mode = Models.Response.SearchMode.REGEX;
            } else {
                res.search_mode = Models.Response.SearchMode.TEXT;
            }
        }

        [GtkCallback]
        private void on_filter_button_toggled() {
            debug("Filter button toggled.");
            var res = root_state.active_request.response;
            if (filter_use_regex_button.active) {
                res.filter_mode = Models.Response.FilterMode.REGEX;
            } else if (filter_use_path_filter_button.active) {
                res.filter_mode = Models.Response.FilterMode.PATH;
            } else if (filter_use_glob_button.active) {
                res.filter_mode = Models.Response.FilterMode.GLOB;
            } else { // Text filter
                res.filter_mode = Models.Response.FilterMode.TEXT;
            }
        }
    }
}