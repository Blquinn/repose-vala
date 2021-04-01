/* request_container.vala
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
    using Repose.Models;

	[GtkTemplate(ui = "/me/blq/Repose/ui/RequestContainer.ui")]
    public class RequestContainer : Gtk.Box {
        [GtkChild] private Gtk.Notebook request_attributes_notebook;
        [GtkChild] private Gtk.Notebook request_type_notebook;
        [GtkChild] private Gtk.ListStore request_type_popover_store;
        [GtkChild] private Gtk.Popover request_type_popover;
        [GtkChild] private Gtk.TreeView request_type_popover_tree_view;
        [GtkChild] private Gtk.SourceView request_text;
        //  private Gtk.SourceBuffer request_text_buffer;

        private ParamTable param_table;
        private ParamTable header_table;

        private ParamTable request_form_data;
        private ParamTable request_form_urlencoded;

        private Gtk.SourceLanguageManager lang_manager;
        private Gtk.SourceStyleSchemeManager style_manager;
        private Gtk.SourceStyleScheme kate_theme;

        private Models.RootState root_state;

        public RequestContainer(Models.RootState root_state) {
            this.root_state = root_state;

            param_table = new ParamTable();
            header_table = new ParamTable();
            request_attributes_notebook.prepend_page(header_table, new Gtk.Label("Headers"));
            request_attributes_notebook.prepend_page(param_table, new Gtk.Label("Params"));
            //  request_attributes_notebook.set_current_page(0);

            request_form_data = new ParamTable();
            request_form_urlencoded = new ParamTable();

            request_type_notebook.insert_page(request_form_data, new Gtk.Label("Form Data"), 2);
            request_type_notebook.insert_page(request_form_urlencoded, new Gtk.Label("Form Url-Encoded"), 3);

            request_type_popover.position = Gtk.PositionType.TOP;

            lang_manager = new Gtk.SourceLanguageManager();
            style_manager = new Gtk.SourceStyleSchemeManager();
            kate_theme = style_manager.get_scheme("kate");

            var selection = request_type_popover_tree_view.get_selection();
            selection.select_path(new Gtk.TreePath.from_indices(0, 0));

            // Bindings

            root_state.active_request_changed.connect(on_active_request_changed);

            request_type_popover_tree_view.row_activated.connect(request_type_popover_row_activated);
        }

        private void on_active_request_changed() {
            var req = root_state.active_request;
            header_table.set_model(req.headers_store);
            param_table.set_model(req.params_store);
            request_form_data.set_model(req.request_bodies.form);
            request_form_urlencoded.set_model(req.request_bodies.form_url);

            var raw_body = req.request_bodies.raw;

            string lang_id = Utils.EditorLangs.RAW_BODY_TYPE_TO_LANG_ID.get(raw_body.active_type);

            raw_body.body.set_language(lang_manager.get_language(lang_id));
            raw_body.body.set_style_scheme(kate_theme);
            request_text.buffer = raw_body.body;

            request_attributes_notebook.set_current_page((int) req.active_attribute);
            request_type_notebook.set_current_page((int) req.active_body_type);
        }

        private void request_type_popover_row_activated(Gtk.TreePath path, Gtk.TreeViewColumn column) {
            Gtk.TreeIter iter;
            request_type_popover_store.get_iter(out iter, path);
            Value val;
            request_type_popover_store.get_value(iter, 1, out val);

            var lang_id = val.get_string();

            message("Selected request body type: %s", lang_id);

            var source_id = Utils.EditorLangs.LANG_ID_TO_SOURCE_ID.get(lang_id);
            
            request_type_popover.popdown();

            var language = lang_manager.get_language(source_id);

            root_state.active_request.request_bodies.raw.body.set_language(language);
            var active_type = Utils.EditorLangs.LANG_ID_TO_RAW_BODY_TYPE.get(lang_id);
            root_state.active_request.request_bodies.raw.active_type = active_type; 

            if (lang_id == "text") {
                root_state.active_request.headers_store.delete_row_by_key("Content-Type");
            } else {
                var mime_type = Utils.EditorLangs.RAW_BODY_TYPE_TO_MIME_TYPE.get(active_type);
                root_state.active_request.headers_store.prepent_or_udpate_row_by_key(
                    new Models.ParamRow("Content-Type", mime_type, "")
                );
            }
        }

        [GtkCallback]
        private void on_request_attributes_notebook_switch_page(Gtk.Widget page, uint offset) {
            switch (offset) {
            case 0:
                root_state.active_request.active_attribute = Models.Request.Attribute.PARAMS;
                break;
            case 1:
                root_state.active_request.active_attribute = Models.Request.Attribute.HEADERS;
                break;
            case 2:
                root_state.active_request.active_attribute = Models.Request.Attribute.BODY;
                break;
            }
        }

        [GtkCallback]
        private void on_request_type_notebook_switch_page(Gtk.Widget page, uint offset) {
            switch (offset) {
            case 0:
                root_state.active_request.active_body_type = Models.Request.BodyType.NONE;
                break;
            case 1:
                root_state.active_request.active_body_type = Models.Request.BodyType.RAW;
                break;
            case 2:
                root_state.active_request.active_body_type = Models.Request.BodyType.FORM;
                break;
            case 3:
                root_state.active_request.active_body_type = Models.Request.BodyType.FORM_URL;
                break;
            case 4:
                root_state.active_request.active_body_type = Models.Request.BodyType.BINARY;
                break;
            }

            set_content_type_for_request_type(root_state.active_request.active_body_type);
        }

        private void set_content_type_for_request_type(Models.Request.BodyType bt) {
            switch (bt) {
            case Models.Request.BodyType.NONE:
                root_state.active_request.headers_store.delete_row_by_key("Content-Type");
                break;
            case Models.Request.BodyType.RAW:
                var active_type = root_state.active_request.request_bodies.raw.active_type;
                var mime_type = Utils.EditorLangs.RAW_BODY_TYPE_TO_MIME_TYPE.get(active_type);
                root_state.active_request.headers_store.prepent_or_udpate_row_by_key(
                    new Models.ParamRow("Content-Type", mime_type, ""));
                break;
            case Models.Request.BodyType.FORM:
                root_state.active_request.headers_store.prepent_or_udpate_row_by_key(
                    new Models.ParamRow("Content-Type", "application/form-data", ""));
                break;
            case Models.Request.BodyType.FORM_URL:
                root_state.active_request.headers_store.prepent_or_udpate_row_by_key(
                    new Models.ParamRow("Content-Type", "application/x-www-form-urlencoded", ""));
                break;
            case Models.Request.BodyType.BINARY:
                root_state.active_request.headers_store.prepent_or_udpate_row_by_key(
                    new Models.ParamRow("Content-Type", "application/octet-stream", ""));
                break;
            }
        }
    }
}
