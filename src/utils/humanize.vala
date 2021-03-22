/* humanize.vala
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

namespace Repose.Utils.Humanize {
    public string timespan(TimeSpan s) {
        if (s > TimeSpan.MINUTE) {
            double d = s;
            d /= TimeSpan.MINUTE;
            return "%.2fm".printf(d);
        }

        if (s > TimeSpan.SECOND) {
            double d = s;
            d /= TimeSpan.SECOND;
            return "%.2fs".printf(d);
        } 

        if (s > TimeSpan.MILLISECOND) {
            return "%dms".printf((int)(s / TimeSpan.MILLISECOND));
        }

        return "%dµs".printf((int)s);
    }

    private double logn(double n, double b) {
        return Math.log(n) / Math.log(b);
    }

    private const string[] sizes = {"B", "kB", "MB", "GB", "TB", "PB", "EB"};

    public string bytes(size_t s) {
        double b = 1000;

        if (s < 10) {
            return "%d B".printf((int) s);
        }
        var e = Math.floor(logn(s, b));
        var suffix = sizes[(int)e];
        var pp = Math.pow(b, e);
        var val = Math.floor(s / pp*10+0.5) / 10;
        var f = "%.0f %s";
        if (val < 10) {
            f = "%.1f %s";
        }
    
        return f.printf(val, suffix);
    }
}