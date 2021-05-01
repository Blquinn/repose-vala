/* request.vala
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

namespace Repose.Models {
    public class RawBody : Object {
        public enum RawBodyType {
            PLAIN_TEXT,
            JSON,
            JAVASCRIPT,
            XML,
            XML_TEXT,
            HTML,
        }

        public RawBodyType active_type { get; set; default = RawBodyType.PLAIN_TEXT; }
        public Gtk.SourceBuffer body { get; set; default = new Gtk.SourceBuffer(null); }

        public static string body_type_to_mime(RawBodyType typ) {
            switch (typ) {
            case PLAIN_TEXT:
                return "text/plain";
            case JSON:
                return "application/json";
            case JAVASCRIPT:
                return "application/javascript";
            case XML:
                return "application/xml";
            case XML_TEXT:
                return "text/xml";
            case HTML:
                return "text/html";
            default:
                return "";
            }
        }
        
        public static string body_type_to_sv_lang(RawBodyType typ) {
            switch (typ) {
            case PLAIN_TEXT:
                return "text-plain";
            case JSON:
                return "json";
            case JAVASCRIPT:
                return "js";
            case XML:
                return "xml-application";
            case XML_TEXT:
                return "xml-text";
            case HTML:
                return "html";
            default:
                return "";
            }
        }
    }

    public class RequestBodies : Object {
        public RawBody raw { get; set; default = new RawBody(); }

        // ListStore of ParamRow
        public ParamTableListStore form { 
            get; 
            default = new ParamTableListStore();
        }

        // ListStore of ParamRow
        public ParamTableListStore form_url { 
            get; 
            //  default = new ListStore(typeof(ParamRow)); 
            default = new ParamTableListStore();
        }

        // Binary stores the file path for the binary file.
        public string binary { get; set; default = ""; }
    }
    
    public class Request : Object {
        public enum Tab {
            REQUEST,
            RESPONSE
        }

        public enum Attribute {
            PARAMS,
            HEADERS,
            BODY,
        }

        public enum BodyType {
            NONE,
            RAW,
            FORM,
            FORM_URL,
            BINARY,
        }

        public string id { get; set; }
        public string? parent_id { get; set; }
        public string name { get; set; }
        public string name_display { 
            get {
                return name == "" ? "New Request" : name;
            }
        }
        public string url { get; set; }
        public string method { get; set; }
        public Tab active_tab { get; set; default = Tab.REQUEST; }
        public Attribute active_attribute { get; set; default = Attribute.PARAMS; }
        public BodyType active_body_type { get; set; default = BodyType.NONE; }
        public RequestBodies request_bodies { get; set; default = new RequestBodies(); }
        public Response response { get; set; }
        public bool request_running { get; set; default = false; }
        public Cancellable? cancellable { get; set; }
        public ParamTableListStore params_store {
            get; 
            default = new ParamTableListStore();
        }
        public ParamTableListStore headers_store {
            get; 
            default = new ParamTableListStore();
        }

        public Request(string id, string? parent_id, string name, string url, string method) {
            this.id = id;
            this.parent_id = parent_id;
            this.name = name;
            this.url = url;
            this.method = method;
            this.response = new Response(this);
        }

        public static Request empty() {
            return new Request(Uuid.string_random(), null, "", "", "GET");
        }

        public void cancel() {
            if (cancellable != null) {
                cancellable.cancel();
                cancellable = null;
            }
        }

        public static Request from_row(Db.RequestNodeRow row) throws Error {
            assert(row.request_json != null);
            var dto = (Db.RequestDto) Json.gobject_from_data(typeof(Db.RequestDto), row.request_json);
            return new Request(row.id, row.parent_id, dto.name, dto.url, dto.method);
        }

        public Db.RequestDto to_dto() {
            return new Db.RequestDto(id, parent_id, name, url, method);
        }

        public Db.RequestNodeRow to_row() throws Error {
            return new Db.RequestNodeRow(id, parent_id, null, Json.gobject_to_data(this.to_dto(), null));
        }
    }
}
