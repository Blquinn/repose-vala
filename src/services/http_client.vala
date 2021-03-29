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

        public async void do_request(Models.Request req, Models.Response res) { 
            message("Beggining request %s to %s", req.name, req.url);
            res.error_text = "";
            res.response_file_path = "";
            res.body_length = 0;
            res.headers.remove_range(0, res.headers.length);

            var start = new DateTime.now_local();

            var cancel = new Cancellable();
            req.cancellable = cancel;

            try {
                var sess = new Soup.Session();
                // TODO: Validate url
                var msg = new Soup.Message(req.method, req.url);

                req.request_running = true;

                // TODO: Implement cancelation.
                InputStream stream;
                try {
                    stream = yield sess.send_async(msg, cancel);
                } catch(Error e) {
                    message("Request failed: %s", e.message);
                    res.error_text = "Error: %s".printf(e.message);
                    req.request_running = false;
                    return;
                }

                res.status_code = msg.status_code;
                HashTable<string, string> content_type_params = new HashTable<string, string>(null, null);
                var ct = msg.response_headers.get_content_type(out content_type_params);
                res.content_type = ct;

                msg.response_headers.foreach((k, v) => {
                    res.headers.append_val(new Models.ParamRow(k, v, ""));
                });

                long len = 0;
                string len_str = msg.response_headers.get_one("Content-Length");
                if (len_str != null) {
                    if (!long.try_parse(len_str, out len)) {
                        message("Failed to parse content-length header: %s", len_str);
                    }
                }

                string? text_encoding = null;

                if (ContentType.is_a(ct, "octet-stream")) {
                    text_encoding = Models.Response.BINARY_BODY;
                }

                if (text_encoding == null){
                    var cs = content_type_params.get("charset");
                    if (cs != null && cs != "") {
                        cs = cs.up();
                        message("Got charset from content-type: %s", cs);
                        text_encoding = cs;
                    }
                }

                FileIOStream tmp_file;
                File file;
                try {
                    file = File.new_tmp("repose-response-XXXXXX", out tmp_file);
                } catch (Error e) {
                    var err_msg = "Failed to open tmp response file: %s".printf(e.message);
                    warning(err_msg);
                    res.error_text = err_msg;
                    return;
                }
                
                res.response_file_path = file.get_path();

                message("Downloading response to: %s", res.response_file_path);

                var charset_detector = new UcharDet.Classifier();

                // Correct character detection requires reading the whole response.
                // Therefore, stream the whole response to a tmp file, run character
                // detection on the streamed response, then store the detected charset.
                //
                // Do the charset conversion when the file is read.
                while (true) {
                    Bytes bts;
                    try {
                        //  yield stream.read_all_async(bts, Priority.DEFAULT, cancel, out bts_read);
                        bts = yield stream.read_bytes_async(4<<10, Priority.DEFAULT, cancel);
                        res.body_length += bts.length;
                        message("Read %d bytes from response", bts.length);
                    } catch (Error e) {
                        var err_msg = "Failed to read response: %s".printf(e.message);
                        warning(err_msg);
                        res.error_text = err_msg;
                        return;
                    }

                    if (bts.length == 0) break;

                    // If the body is not binary and we haven't opened a conversion stream yet.
                    if (text_encoding != Models.Response.BINARY_BODY) {
                        charset_detector.handle_data(bts.get_data());
                    }

                    try {
                        yield tmp_file.output_stream.write_bytes_async(bts, Priority.DEFAULT, cancel);
                        message("Wrote %d bytes to tmp file.", bts.length);
                    } catch (Error e) {
                        var err_msg = "Failed to read response: %s".printf(e.message);
                        warning(err_msg);
                        res.error_text = err_msg;
                        return;
                    }
                }

                try {
                    yield tmp_file.output_stream.close_async(Priority.DEFAULT, cancel);
                    yield tmp_file.close_async(Priority.DEFAULT, cancel);
                } catch (Error e) {
                    var err_msg = "Failed to close tmp file: %s".printf(e.message);
                    warning(err_msg);
                    res.error_text = err_msg;
                    return;
                }

                // Set charset
                if (text_encoding == Models.Response.BINARY_BODY) {
                    res.text_encoding = text_encoding;
                    return;
                }
                if (charset_detector == null && text_encoding == null) {
                    message("No detected character encoding, treating as binary.");
                    res.text_encoding = Models.Response.BINARY_BODY;
                    return;
                }
                if (charset_detector != null) {
                    charset_detector.data_end();
                    var cdt = charset_detector.get_charset();

                    message("Detected character encoding: %s", cdt);
                    if (cdt.up() != text_encoding.up()) {
                        message("Content-Type text encoding: %s not equal detected encoding: %s", text_encoding, cdt);
                    }

                    // Prefer detected charset.
                    res.text_encoding = cdt;
                    return;
                }

                res.text_encoding = text_encoding;
            } finally {
                message("Using %s character encoding.", res.text_encoding);

                res.response_time = new DateTime.now_local().difference(start);
                req.request_running = false;
                res.response_received();
            }
        }
    }
}
