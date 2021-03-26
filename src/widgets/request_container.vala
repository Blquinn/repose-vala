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
	[GtkTemplate(ui = "/me/blq/Repose/ui/RequestContainer.ui")]
    public class RequestContainer : Gtk.Box {
        [GtkChild] private Gtk.Notebook request_attributes_notebook;
        [GtkChild] private Gtk.Notebook request_type_notebook;
        //  [GtkChild] private Gtk.ListStore request_type_popover_store;
        //  [GtkChild] private Gtk.Popover request_type_popover;
        //  [GtkChild] private Gtk.TreeView request_type_popover_tree_view;
        //  [GtkChild] private Gtk.SourceView request_text;

        private ParamTable param_table;
        private ParamTable header_table;

        private ParamTable request_form_data;
        private ParamTable request_form_urlencoded;

        public RequestContainer() {
            param_table = new ParamTable();
            header_table = new ParamTable();
            request_attributes_notebook.prepend_page(header_table, new Gtk.Label("Headers"));
            request_attributes_notebook.prepend_page(param_table, new Gtk.Label("Params"));
            //  request_attributes_notebook.set_current_page(0);

            request_form_data = new ParamTable();
            request_form_urlencoded = new ParamTable();

            request_type_notebook.insert_page(request_form_data, new Gtk.Label("Form Data"), 2);
            request_type_notebook.insert_page(request_form_urlencoded, new Gtk.Label("Form Url-Encoded"), 3);
        }
    }
    
    //  [GtkCallback]
    //  void populate_response_text_context_menu(Gtk.TextView view, Gtk.Widget popup) {}
}
