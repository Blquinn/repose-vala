/* dirs.vala
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
    public class Dirs {
        public static string tmp;
        private static string alphabet = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";

        static construct {
            Random.set_seed((uint32)get_real_time());
            tmp = Path.build_filename(Environment.get_tmp_dir(), "repose", "responses");
        }

        public static string gen_rand_tmp_path(int name_size = 6) {
            var chars = new char[name_size];
            for (int i = 0; i < name_size; i++) {
                var c_idx = Random.int_range(0, alphabet.length);
                chars[i] = alphabet[c_idx];
            }
            return Path.build_filename(tmp, (string) chars);
        }
    }
}
