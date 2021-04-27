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

using Repose;
using Repose.Models.Db;

int main (string[] args) {
	message("Starting Repose application.");
	var app = new Gtk.Application("me.blq.Repose", ApplicationFlags.FLAGS_NONE);

	typeof(Gtk.SourceView).ensure();
	{  // Initialize static vars
		new Utils.EditorLangs(); 
		new Utils.Dirs(); 
	}

	Utils.Dirs.create_dirs();

	var db_path = Path.build_filename(Utils.Dirs.data, "repose.db");
	Sqlite.Database db;
	var ec = Sqlite.Database.open(db_path, out db);
	if (ec != Sqlite.OK) {
		error("Failed to open sqlite database: %d", ec);
	}

	var request_dao = new Services.RequestDao(db);
	request_dao.create_tables();

	//  try {
	//  	var reqs = request_dao.get_requests();
	//  	var nodes = Models.RequestTreeNode.from_rows(reqs);
	//  	message("NOdes len %d", nodes.size);
	//  	foreach (var n in nodes) message("NOdes child len %d", n.children.size);
	//  } catch (Error e) {}

	app.activate.connect(() => {

		load_css();

		var win = app.active_window;
		if (win == null) {
			message("Creating application window.");
			win = new Widgets.MainWindow(app, new Models.RootState(request_dao));
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
