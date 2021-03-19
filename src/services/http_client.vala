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
        public void do_request(Models.Request req, Models.Response res) {
            message("Beggining request %s to %s", req.name, req.url);

            var sess = new Soup.Session();
            var http_req = new Soup.Message(req.method, req.url);

            var start = new DateTime.now_local();
            sess.queue_message(http_req, (sess, msg) => {
                res.status_code = msg.status_code;
                res.response_time = new DateTime.now_local().difference(start);

                // TODO: Make this more defensive.
                string ct = msg.response_headers.get_one("Content-Type");
                string[] chunks = ct.split("; ");
                if (chunks.length > 1) {
                    string ee = chunks[1];
                    string enc = ee.split("=")[1];
                    try {
                        res.body = convert((string) msg.response_body.data, -1, "UTF-8", enc);
                    } catch (ConvertError e) {
                        res.body = "Error: Failed to decode response text.";
                    }
                } else {
                    // Assume utf-8
                    var body = (string) msg.response_body.data;
                    if (body.validate()) {
                        res.body = body;
                    } else {
                        res.body = "Error: Reponse is invalid UTF-8.";
                    }
                }

                //  message("Request %s to %s completed in %dus. Body encoding: %s.", req.name, req.url, (int) res.response_time, enc);

                res.content_type = msg.response_headers.get_content_type(null);
                msg.response_headers.foreach((k, v) => {
                    res.headers.append_val(new Models.ParamRow(k, v, ""));
                });

                res.response_received();
            });
        }
    }
}
