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

    public size_t encode(uint8[] src, uint8[] dst) {
        size_t i = 0;
        foreach (var b in src) {
            dst[i] = hextable[b>>4];
            dst[i+1] = hextable[b&0x0f];
            i += 2;
        }
        return src.length * 2;
    }

    //  public class Dumper {
    //      //  w          io.Writer
    //      //  rightChars [18]byte
    //      //  buf        [14]byte
    //      //  used       int  // number of bytes in the current line
    //      //  n          uint // number of bytes, total
    //      //  closed     bool
    //      private OuputStream w;
    //      private uint n;
    //  }

    //  private uint8 toChar(uint8 b) {
    //      return (b < 32 || b > 126) ? '.' : b;
    //  }

    //  func (h *dumper) Write(data []byte) (n int, err error) {
    //      if h.closed {
    //          return 0, errors.New("encoding/hex: dumper closed")
    //      }

    //      // Output lines look like:
    //      // 00000010  2e 2f 30 31 32 33 34 35  36 37 38 39 3a 3b 3c 3d  |./0123456789:;<=|
    //      // ^ offset                          ^ extra space              ^ ASCII of line.
    //      for i := range data {
    //          if h.used == 0 {
    //              // At the beginning of a line we print the current
    //              // offset in hex.
    //              h.buf[0] = byte(h.n >> 24)
    //              h.buf[1] = byte(h.n >> 16)
    //              h.buf[2] = byte(h.n >> 8)
    //              h.buf[3] = byte(h.n)
    //              Encode(h.buf[4:], h.buf[:4])
    //              h.buf[12] = ' '
    //              h.buf[13] = ' '
    //              _, err = h.w.Write(h.buf[4:])
    //              if err != nil {
    //                  return
    //              }
    //          }
    //          Encode(h.buf[:], data[i:i+1])
    //          h.buf[2] = ' '
    //          l := 3
    //          if h.used == 7 {
    //              // There's an additional space after the 8th byte.
    //              h.buf[3] = ' '
    //              l = 4
    //          } else if h.used == 15 {
    //              // At the end of the line there's an extra space and
    //              // the bar for the right column.
    //              h.buf[3] = ' '
    //              h.buf[4] = '|'
    //              l = 5
    //          }
    //          _, err = h.w.Write(h.buf[:l])
    //          if err != nil {
    //              return
    //          }
    //          n++
    //          h.rightChars[h.used] = toChar(data[i])
    //          h.used++
    //          h.n++
    //          if h.used == 16 {
    //              h.rightChars[16] = '|'
    //              h.rightChars[17] = '\n'
    //              _, err = h.w.Write(h.rightChars[:])
    //              if err != nil {
    //                  return
    //              }
    //              h.used = 0
    //          }
    //      }
    //      return
    //  }

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
