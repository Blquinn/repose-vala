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

        private const size_t READ_SIZE = 16<<10; // 16 KiB
        private const size_t MAX_BODY_SIZE = 10<<20; // 10 MiB
        private static string MAX_BODY_SIZE_HR = Utils.Humanize.bytes(MAX_BODY_SIZE);
        private const string BINARY_BODY = "__BINARY__";

        public async void do_request(Models.Request req, Models.Response res) { message("Beggining request %s to %s", req.name, req.url);
            res.body.text = "";
            res.headers.remove_range(0, res.headers.length);

            size_t bytes_read = 0;
            var start = new DateTime.now_local();

            IConv? text_converter = null;

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
                    res.body.text = "Error: %s".printf(e.message);
                    req.request_running = false;
                    return;
                }
                    
                res.status_code = msg.status_code;
                var content_type_params = new HashTable<string, string>(null, null);
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

                if (len > MAX_BODY_SIZE) {
                    res.body.text = @"Response size is greater than maximum displayable size of $(MAX_BODY_SIZE_HR)";
                    return;
                }

                string? text_encoding = null;

                if (ContentType.is_a(ct, "octet-stream")) {
                    text_encoding = BINARY_BODY;
                }

                if (text_encoding == null){
                    var cs = content_type_params.get("charset");
                    if (cs != null && cs != "") text_encoding = cs;
                }

                var body = new Array<uint8>();
                while (true) {
                    Bytes bts;
                    try {
                        bts = yield stream.read_bytes_async(READ_SIZE);
                    } catch (Error e) {
                        res.body.text = "Error: %s".printf(e.message);
                        return;
                    }

                    if (bts.length == 0) {
                        message("Done receiving response body.");
                        break;
                    }

                    body.append_vals(bts.get_data(), bts.length);

                    if (body.length > MAX_BODY_SIZE) {
                        res.body.text = @"Response size is greater than maximum displayable size of $(MAX_BODY_SIZE_HR)";
                        return;
                    }
                }

                var bts = body.data;
                bytes_read = bts.length;

                // Try to detect encoding on first chunk of body.
                if (text_encoding == null || text_encoding == "") {
                    var cd = new UcharDet.Classifier();
                    cd.handle_data(bts); // TODO: Handle return code.
                    cd.data_end();
                    var cs = cd.get_charset();
                    if (cs != "") {
                        message("Detected charset: %s", cs);
                        text_encoding = cs;
                    }
                }

                switch (text_encoding) {
                case null:
                case BINARY_BODY:
                    var hex = Utils.Hexdump.encodeCannonical(bts);
                    res.body.text = hex;
                    return;
                case "UTF-8":
                case "ASCII":
                    var body_txt = (string)bts;
                    if (!body_txt.validate(body_txt.length)) {
                        res.body.text = "Error: non-utf-8 character detected.";
                        return;
                    }

                    res.body.text = body_txt;
                    break;
                default:
                    var body_txt = (string)bts;
                    try {
                        res.body.text = convert(body_txt, body_txt.length, "UTF-8", text_encoding);
                    } catch (ConvertError e) {
                        res.body.text = "Error: Failed to convert text to UTF-8: %s".printf(e.message);
                    }
                    break;
                }
            } finally {
                if (text_converter != null) text_converter.close();

                res.body_length = bytes_read;
                res.response_time = new DateTime.now_local().difference(start);
                req.request_running = false;
                res.response_received();
            }
        }
        //  public async void do_request(Models.Request req, Models.Response res) { message("Beggining request %s to %s", req.name, req.url);
            
        //      res.body.text = "";
        //      size_t bytes_read = 0;
        //      var start = new DateTime.now_local();

        //      IConv? text_converter = null;

        //      try {
        //          var sess = new Soup.Session();
        //          // TODO: Validate url
        //          var msg = new Soup.Message(req.method, req.url);

        //          req.request_running = true;

        //          // TODO: Implement cancelation.
        //          InputStream stream;
        //          try {
        //              stream = yield sess.send_async(msg);
        //          } catch(Error e) {
        //              res.body.text = "Error: %s".printf(e.message);
        //              req.request_running = false;
        //              return;
        //          }
                    
        //          res.status_code = msg.status_code;

        //          // TODO: Make this more defensive.
        //          string ct = msg.response_headers.get_one("Content-Type");

        //          string? text_encoding = null;

        //          if (ContentType.is_a(ct, "octet-stream")) {
        //              text_encoding = BINARY_BODY;
        //          }

        //          if (text_encoding == null){
        //              string[] chunks = ct.split(";");

        //              foreach (var chunk in chunks) {
        //                  string[] segments = chunk.strip().split("=");
        //                  if (segments.length > 1 && segments[0].down() == "charset") { 
        //                      text_encoding = segments[1].up();
        //                      break;
        //                  }
        //              }
        //          }

        //          res.content_type = msg.response_headers.get_content_type(null);
        //          msg.response_headers.foreach((k, v) => {
        //              res.headers.append_val(new Models.ParamRow(k, v, ""));
        //          });


        //          while (true) {
        //              Bytes bts;
        //              try {
        //                  bts = yield stream.read_bytes_async(READ_SIZE);
        //              } catch (Error e) {
        //                  res.body.text = "Error: %s".printf(e.message);
        //                  return;
        //              }

        //              if (bts.length == 0) {
        //                  message("Done receiving response body.");
        //                  return;
        //              }

        //              bytes_read += bts.length;

        //              debug("Received %d bytes of response data.", bts.length);

        //              // Try to detect encoding on first chunk of body.
        //              if (text_encoding == null || text_encoding == "") {
        //                  var cd = new UcharDet.Classifier();
        //                  cd.handle_data(bts.get_data()); // TODO: Handle return code.
        //                  cd.data_end();
        //                  var cs = cd.get_charset();
        //                  if (cs != "") {
        //                      message("Detected charset: %s", cs);
        //                      text_encoding = cs;
        //                  }
        //              }

        //              debug("Using response encoding: %s", text_encoding);

        //              if (text_encoding != null && text_encoding != "") {
        //                  text_converter = IConv.open("UTF-8", text_encoding);
        //              }

        //              // TODO: Stream body chunks to sourceview.
        //              message(text_encoding);

        //              switch (text_encoding) {
        //              case "__BINARY__": // Binary
        //                  res.body.text = "Binary response body.";
        //                  return;
        //              case "UTF-8":
        //                  var body = (string)bts.get_data();
        //                  //  if (!body.validate(bts.length)) {
        //                  if (!body.validate()) {
        //                      res.body.text = "Error: non-utf-8 character detected.";
        //                      return;
        //                  }

        //                  Gtk.TextIter end_it;
        //                  res.body.get_end_iter(out end_it);
        //                  res.body.insert(ref end_it, body, body.length);
        //                  break;
        //              default: // We have a non-utf-8 text encoding to convert.
        //                  try {
        //                      var converted = convert_with_iconv((string) bts.get_data(), bts.length, text_converter);

        //                      Gtk.TextIter end_it;
        //                      res.body.get_end_iter(out end_it);
        //                      res.body.insert(ref end_it, converted, converted.length);
        //                  } catch (ConvertError e) {
        //                      res.body.text = "Error: Failed to convert text to UTF-8: %s".printf(e.message);
        //                  }
        //                  break;
        //              }
        //          }
        //      } finally {
        //          if (text_converter != null) text_converter.close();

        //          res.body_length = bytes_read;
        //          res.response_time = new DateTime.now_local().difference(start);
        //          req.request_running = false;
        //          res.response_received();
        //      }
        //  }
    }
}
