/* hex_dump.vala
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

namespace Repose.Utils.Hexdump {
    const char[] hextable = {'0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f'};

    public void encode(uint8[] dst, uint8[] src) {
        size_t i = 0;
        foreach (var b in src) {
            dst[i] = hextable[b >> 4];
            dst[i+1] = hextable[b & 0x0f];
            i += 2;
        }
    }

    private uint8 toChar(uint8 b) {
        return (b < 32 || b > 126) ? '.' : b;
    }

    public string encodeCannonical(uint8[] src) {
        // Output lines look like:
        // 00000010  2e 2f 30 31 32 33 34 35  36 37 38 39 3a 3b 3c 3d  |./0123456789:;<=|
        // ^ offset                          ^ extra space              ^ ASCII of line.
        //  var n = src.length;
        var n = 0;
        var sb = new StringBuilder();
        var rightChars = new uint8[18];
        var buf = new uint8[14];
        var used = 0;

        //  foreach (var i in src) {
        for (var i = 0; i < src.length; i++) {
            if (used == 0) {
                // At the beginning of a line we print the current
                // offset in hex.
                buf[0] = (uint8) n >> 24;
                buf[1] = (uint8) n >> 16;
                buf[2] = (uint8) n >> 8;
                buf[3] = (uint8) n;
                encode(buf[4:buf.length], buf[0:4]);
                buf[12] = ' ';
                buf[13] = ' ';
                sb.append((string) buf[4:buf.length]);
            }
            encode(buf[0:buf.length], src[i:i+1]);
            buf[2] = ' ';
            var l = 3;
            if (used == 7) {
                // There's an additional space after the 8th byte.
                buf[3] = ' ';
                l = 4;
            } else if (used == 15) {
                // At the end of the line there's an extra space and
                // the bar for the right column.
                buf[3] = ' ';
                buf[4] = '|';
                l = 5;
            }
            sb.append((string) buf[0:l]);
            n++;
            rightChars[used] = toChar(src[i]);
            used++;
            n++;
            if (used == 16) {
                rightChars[16] = '|';
                rightChars[17] = '\n';
                sb.append((string) rightChars);
                used = 0;
            }
        }

        // Close

        if (used == 0) {
            return sb.str;
        }

        buf[0] = ' ';
        buf[1] = ' ';
        buf[2] = ' ';
        buf[3] = ' ';
        buf[4] = '|';
        var nBytes = used;
        while (used < 16) {
            var l = 3;
            if (used == 7) {
                l = 4;
            } else if (used == 15) {
                l = 5;
            }
            sb.append((string) buf[0:l]);
            used++;
        }
        rightChars[nBytes] = '|';
        rightChars[nBytes+1] = '\n';
        sb.append((string) rightChars[0:nBytes+2]);

        return sb.str;
    }

    //  func (h *dumper) Close() (err error) {
    //      // See the comments in Write() for the details of this format.
    //      if h.closed {
    //          return
    //      }
    //      h.closed = true
    //      if h.used == 0 {
    //          return
    //      }
    //      h.buf[0] = ' '
    //      h.buf[1] = ' '
    //      h.buf[2] = ' '
    //      h.buf[3] = ' '
    //      h.buf[4] = '|'
    //      nBytes := h.used
    //      for h.used < 16 {
    //          l := 3
    //          if h.used == 7 {
    //              l = 4
    //          } else if h.used == 15 {
    //              l = 5
    //          }
    //          _, err = h.w.Write(h.buf[:l])
    //          if err != nil {
    //              return
    //          }
    //          h.used++
    //      }
    //      h.rightChars[nBytes] = '|'
    //      h.rightChars[nBytes+1] = '\n'
    //      _, err = h.w.Write(h.rightChars[:nBytes+2])
    //      return
    //  }

}
