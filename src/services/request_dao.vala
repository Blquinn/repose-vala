/* request_dao.vala
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

namespace Repose.Services {

    using Repose;
    
    /*
    NOTE: Sqlite uses 0 based column indexes for selects, but 1 based indexes 
        for prepared statement arguments.
    */

    using Repose.Models.Db;

    public class RequestDao {
        private unowned Sqlite.Database db;

        public RequestDao(Sqlite.Database db) {
            this.db = db;
        }

        public Gee.List<RequestNodeRow> get_requests() throws Error {
            const string query = """ 
                select id, parent_id, folder_json, request_json 
                from requests
                order by parent_id desc
                ;
            """;
            Sqlite.Statement stmt;
            var rc = db.prepare_v2(query, query.length, out stmt);
            if (rc != Sqlite.OK) {
                message("Failed to prepare get requests statement, errcode: %d", rc);
                throw new Error(Quark.from_string("error"), rc, "Failed to prepare get requets statement, errcode: %d", rc);
            }

            var requests = new Gee.ArrayList<RequestNodeRow>();
            while (stmt.step() == Sqlite.ROW) {
                requests.add(new RequestNodeRow(
                    stmt.column_text(0),
                    stmt.column_text(1),
                    stmt.column_text(2),
                    stmt.column_text(3)
                ));
            }
            return requests;
        }

        public void insert_request(RequestNodeRow request) throws Error {
            const string query = """
            insert into requests (id, parent_id, folder_json, request_json) values (?, ?, ?, ?)
            """;

            Sqlite.Statement stmt;
            var rc = db.prepare_v2(query, query.length, out stmt);
            if (rc != Sqlite.OK) {
                message("Failed to prepare save request statement, errcode: %d", rc);
                throw new Error(Quark.from_string("error"), rc, "Failed to prepare save request statement, errcode: %d", rc);
            }

            stmt.bind_text(1, request.id);
            stmt.bind_text(2, request.parent_id);
            stmt.bind_text(3, request.folder_json);
            stmt.bind_text(4, request.request_json);

            rc = stmt.step();
            if (rc != Sqlite.DONE) {
                message("Failed to insert request, errcode: %d", rc);
                throw new Error(Quark.from_string("error"), rc, "Failed to insert request, errcode: %d", rc);
            }
        }

        public void update_request(RequestNodeRow request) throws Error {
            const string query = """
            update requests set parent_id = ?, folder_json = ?, request_json = ?
            where id = ?
            """;

            Sqlite.Statement stmt;
            var rc = db.prepare_v2(query, query.length, out stmt);
            if (rc != Sqlite.OK) {
                message("Failed to prepare update request statement, errcode: %d", rc);
                throw new Error(Quark.from_string("error"), rc, "Failed to prepare update request statement, errcode: %d", rc);
            }

            stmt.bind_text(1, request.parent_id);
            stmt.bind_text(2, request.folder_json);
            stmt.bind_text(3, request.request_json);
            stmt.bind_text(4, request.id);

            rc = stmt.step();
            if (rc != Sqlite.DONE) {
                message("Failed to update request, errcode: %d", rc);
                throw new Error(Quark.from_string("error"), rc, "Failed to insert request, errcode: %d", rc);
            }
        }

        public void create_tables() {
            const string stmt = """create table if not exists requests (
                id text primary key,
                parent_id text references requests,
                folder_json text, 
                request_json text 
            );""";
            string errmsg;
            if (db.exec(stmt, null, out errmsg) != Sqlite.OK) {
                error("Failed to create requests table: %s", errmsg);
            }
        }
    }
}
