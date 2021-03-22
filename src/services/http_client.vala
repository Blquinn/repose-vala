/* http_client.vala
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
using Soup;

namespace Repose.Services {
    public class HttpClient : Object {
        private enum BodyType {
            UTF8,
            TEXT, // Text that requires conversion.
            BINARY,
        }

        private const size_t read_size = 16<<10;

        public async void do_request(Models.Request req, Models.Response res) {
            message("Beggining request %s to %s", req.name, req.url);

            var sess = new Soup.Session();
            // TODO: Validate url
            var msg = new Soup.Message(req.method, req.url);

            req.request_running = true;
            var start = new DateTime.now_local();

            // TODO: Implement cancelation.
            InputStream stream;
            try {
                stream = yield sess.send_async(msg);
            } catch(Error e) {
                return;
            }
                
            res.status_code = msg.status_code;
            res.response_time = new DateTime.now_local().difference(start);
            req.request_running = false;

            //  var body_bytes = msg.response_body.data;
            //  res.body_length = body_bytes.length;
            //  var body = (string) body_bytes;

            // TODO: Make this more defensive.
            string ct = msg.response_headers.get_one("Content-Type");

            //  bool is_binary = ContentType.is_a(ct, "octet-stream");
            string? text_encoding = null;

            BodyType bt;

            string[] chunks = ct.split(";");

            foreach (var chunk in chunks) {
                string[] segments = chunk.strip().split("=");
                if (segments.length > 1 && segments[0] == "charset"
                    && !(segments[1] == "utf-8"|| segments[1] == "ascii")) { 

                    text_encoding = segments[1];
                    break;
                }
            }

            if (chunks.length > 1) {
                string ee = chunks[1];
                text_encoding = ee.split("=")[1].down();

                //  if (text_encoding == "utf-8" || text_encoding == "ascii") {
                //  }

                //  try {
                //      res.body = convert((string) msg.response_body.data, -1, "UTF-8", enc);
                //  } catch (ConvertError e) {
                //      res.body = "Error: Failed to decode response text.";
                //  }
            } else {
                // Assume utf-8
                //  if (body.validate()) {
                //      res.body = body;
                //  } else {
                //      res.body = "Error: Reponse is invalid UTF-8.";
                //  }
            }


            //  message("Request %s to %s completed in %dus. Body encoding: %s.", req.name, req.url, (int) res.response_time, enc);

            res.content_type = msg.response_headers.get_content_type(null);
            msg.response_headers.foreach((k, v) => {
                res.headers.append_val(new Models.ParamRow(k, v, ""));
            });

            while (true) {
                Bytes bts;
                try {
                    bts = yield stream.read_bytes_async(read_size);
                } catch (Error e) {
                    res.body = "Error: %s".printf(e.message);
                    break;
                }

                if (text_encoding == null || text_encoding == "") {
                    var cd = new UcharDet.Classifier();
                    cd.handle_data(bts.get_data());
                    cd.data_end();
                    var cs = cd.get_charset();
                    if (cs == "") {
                    } else {
                    }
                }

                if (bts.length < read_size) break;
            }

            res.response_received();
        }
    }
}
