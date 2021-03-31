/* main.vala
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

int main (string[] args) {
	var app = new Gtk.Application("me.blq.Repose", ApplicationFlags.FLAGS_NONE);

	typeof(Gtk.SourceView).ensure();
	{ new Repose.Utils.EditorLangs(); }

	app.activate.connect(() => {

		load_css();

		var win = app.active_window;
		if (win == null) {
			win = new Repose.Widgets.MainWindow(app);
		}
		win.present();
	});

	return app.run(args);
}

void load_css() {
	var css_provider = new Gtk.CssProvider();
	css_provider.load_from_resource("/me/blq/Repose/ui/style.css");

	var screen = Gdk.Screen.get_default();

	Gtk.StyleContext.add_provider_for_screen(
		screen,
		css_provider,
		Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
}
