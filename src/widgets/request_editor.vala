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
	[GtkTemplate(ui = "/me/blq/Repose/ui/RequestEditor.ui")]
    public class RequestEditor : Gtk.Box {
        public RequestEditor() {
        }

        [GtkCallback]
        void on_save_pressed(Gtk.Button btn) {}

        [GtkCallback]
        void on_send_pressed(Gtk.Button btn) {}
        
        [GtkCallback]
        void on_request_name_changed() {}
    }
}
