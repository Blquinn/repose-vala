namespace Repose.Models {
    public class FolderModel : Object {
        public string id { get; set; }
        public string name { get; set; }

        public FolderModel(string id, string name) {
            this.id = id;
            this.name = name;
        }

        public static FolderModel from_row(Db.RequestNodeRow row) throws Error {
            assert(row.folder_json != null);
            return (FolderModel) Json.gobject_from_data(typeof(FolderModel), row.folder_json);
        }
    }
}
