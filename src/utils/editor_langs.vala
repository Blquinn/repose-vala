/* editor_langs.vala
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

namespace Repose.Utils {
    public class EditorLangs {
        public static Gee.Map<string, string> LANG_ID_TO_SOURCE_ID = new Gee.HashMap<string, string>(null, null);

        public static Gee.Map<string, string> SOURCE_ID_TO_LANG_ID = new Gee.HashMap<string, string>(null, null);

        public static Gee.Map<string, Models.RawBody.RawBodyType> LANG_ID_TO_RAW_BODY_TYPE 
            = new Gee.HashMap<string, Models.RawBody.RawBodyType>(null, null);
        
        public static Gee.Map<Models.RawBody.RawBodyType, string> RAW_BODY_TYPE_TO_LANG_ID
            = new Gee.HashMap<Models.RawBody.RawBodyType, string>(null, null);
        
        public static Gee.Map<Models.RawBody.RawBodyType, string> RAW_BODY_TYPE_TO_MIME_TYPE
            = new Gee.HashMap<Models.RawBody.RawBodyType, string>(null, null);

        static construct {
            LANG_ID_TO_SOURCE_ID.set("text", "text");
            LANG_ID_TO_SOURCE_ID.set("text-plain", "text");
            LANG_ID_TO_SOURCE_ID.set("json", "json");
            LANG_ID_TO_SOURCE_ID.set("js", "js");
            LANG_ID_TO_SOURCE_ID.set("xml-application", "xml");
            LANG_ID_TO_SOURCE_ID.set("xml-text", "xml");
            LANG_ID_TO_SOURCE_ID.set("html", "html");

            foreach (var entry in LANG_ID_TO_SOURCE_ID) {
                SOURCE_ID_TO_LANG_ID.set(entry.value, entry.key);
            }

            LANG_ID_TO_RAW_BODY_TYPE.set("text", Models.RawBody.RawBodyType.PLAIN_TEXT);
            LANG_ID_TO_RAW_BODY_TYPE.set("text-plain", Models.RawBody.RawBodyType.PLAIN_TEXT);
            LANG_ID_TO_RAW_BODY_TYPE.set("json", Models.RawBody.RawBodyType.JSON);
            LANG_ID_TO_RAW_BODY_TYPE.set("js", Models.RawBody.RawBodyType.JAVASCRIPT);
            LANG_ID_TO_RAW_BODY_TYPE.set("xml-application", Models.RawBody.RawBodyType.XML);
            LANG_ID_TO_RAW_BODY_TYPE.set("xml-text", Models.RawBody.RawBodyType.XML_TEXT);
            LANG_ID_TO_RAW_BODY_TYPE.set("html", Models.RawBody.RawBodyType.HTML);
            
            foreach (var entry in LANG_ID_TO_RAW_BODY_TYPE) {
                RAW_BODY_TYPE_TO_LANG_ID.set(entry.value, entry.key);
            }
            
            RAW_BODY_TYPE_TO_MIME_TYPE.set(Models.RawBody.RawBodyType.PLAIN_TEXT, "text/plain; charset=utf-8");
            RAW_BODY_TYPE_TO_MIME_TYPE.set(Models.RawBody.RawBodyType.JSON, "application/json");
            RAW_BODY_TYPE_TO_MIME_TYPE.set(Models.RawBody.RawBodyType.JAVASCRIPT, "application/javascript");
            RAW_BODY_TYPE_TO_MIME_TYPE.set(Models.RawBody.RawBodyType.XML, "application/xml");
            RAW_BODY_TYPE_TO_MIME_TYPE.set(Models.RawBody.RawBodyType.XML_TEXT, "text/xml");
            RAW_BODY_TYPE_TO_MIME_TYPE.set(Models.RawBody.RawBodyType.HTML, "text/html");
        }
    }
}