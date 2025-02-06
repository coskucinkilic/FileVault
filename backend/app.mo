import Bool "mo:base/Bool";
import Array "mo:base/Array";
import Blob "mo:base/Blob";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Option "mo:base/Option";

actor Filevault {

  // Define a data type for a file's chunks.
  type FileChunk = {
    chunk : Blob;
    index : Nat;
  };

  // Define a data type for a file's data.
  type File = {
    name : Text;
    chunks : [FileChunk];
    totalSize : Nat;
    fileType : Text;
  };

  // Define a data type for storing files associated with a user principal.
  type UserFiles = HashMap.HashMap<Text, File>;

  // Stable variable to store the data across canister upgrades.
  // It is not used during normal operations.
  private stable var stableFiles : [(Principal, [(Text, File)])] = [];
  // HashMap to store the data during normal canister operations.
  // Gets written to stable memory in preupgrade to persist data across canister upgrades.
  // Gets recovered from stable memory in postupgrade.
  private var files = HashMap.HashMap<Principal, UserFiles>(0, Principal.equal, Principal.hash);

  // Return files associated with a user's principal.
  private func getUserFiles(user : Principal) : UserFiles {
    switch (files.get(user)) {
      case null {
        let newFileMap = HashMap.HashMap<Text, File>(0, Text.equal, Text.hash);
        files.put(user, newFileMap);
        newFileMap;
      };
      case (?existingFiles) existingFiles;
    };
  };

  // Check if a file name already exists for the user.
  public shared (msg) func checkFileExists(name : Text) : async Bool {
    Option.isSome(getUserFiles(msg.caller).get(name));
  };

  // Upload a file in chunks.
  public shared (msg) func uploadFileChunk(name : Text, chunk : Blob, index : Nat, fileType : Text) : async () {
    let userFiles = getUserFiles(msg.caller);
    let fileChunk = { chunk = chunk; index = index };

    switch (userFiles.get(name)) {
      case null {
        userFiles.put(name, { name = name; chunks = [fileChunk]; totalSize = chunk.size(); fileType = fileType });
      };
      case (?existingFile) {
        let updatedChunks = Array.append(existingFile.chunks, [fileChunk]);
        userFiles.put(
          name,
          {
            name = name;
            chunks = updatedChunks;
            totalSize = existingFile.totalSize + chunk.size();
            fileType = fileType;
          }
        );
      };
    };
  };

  // Return list of files for a user.
  public shared (msg) func getFiles() : async [{ name : Text; size : Nat; fileType : Text }] {
    Iter.toArray(
      Iter.map(
        getUserFiles(msg.caller).vals(),
        func(file : File) : { name : Text; size : Nat; fileType : Text } {
          {
            name = file.name;
            size = file.totalSize;
            fileType = file.fileType;
          };
        }
      )
    );
  };

  // Return total chunks for a file
  public shared (msg) func getTotalChunks(name : Text) : async Nat {
    switch (getUserFiles(msg.caller).get(name)) {
      case null 0;
      case (?file) file.chunks.size();
    };
  };

  // Return specific chunk for a file.
  public shared (msg) func getFileChunk(name : Text, index : Nat) : async ?Blob {
    switch (getUserFiles(msg.caller).get(name)) {
      case null null;
      case (?file) {
        switch (Array.find(file.chunks, func(chunk : FileChunk) : Bool { chunk.index == index })) {
          case null null;
          case (?foundChunk) ?foundChunk.chunk;
        };
      };
    };
  };

  // Get file's type.
  public shared (msg) func getFileType(name : Text) : async ?Text {
    switch (getUserFiles(msg.caller).get(name)) {
      case null null;
      case (?file) ?file.fileType;
    };
  };

  // Delete a file.
  public shared (msg) func deleteFile(name : Text) : async Bool {
    Option.isSome(getUserFiles(msg.caller).remove(name));
  };

  // Pre-upgrade hook to write data to stable memory.
  system func preupgrade() {
    let entries : Iter.Iter<(Principal, UserFiles)> = files.entries();
    stableFiles := Iter.toArray(
      Iter.map<(Principal, UserFiles), (Principal, [(Text, File)])>(
        entries,
        func((principal, userFiles) : (Principal, UserFiles)) : (Principal, [(Text, File)]) {
          (principal, Iter.toArray(userFiles.entries()));
        }
      )
    );
  };

  // Post-upgrade hook to restore data from stable memory.
  system func postupgrade() {
    files := HashMap.fromIter<Principal, UserFiles>(
      Iter.map<(Principal, [(Text, File)]), (Principal, UserFiles)>(
        stableFiles.vals(),
        func((principal, userFileEntries) : (Principal, [(Text, File)])) : (Principal, UserFiles) {
          let userFiles = HashMap.HashMap<Text, File>(0, Text.equal, Text.hash);
          for ((name, file) in userFileEntries.vals()) {
            userFiles.put(name, file);
          };
          (principal, userFiles);
        }
      ),
      0,
      Principal.equal,
      Principal.hash
    );
    stableFiles := [];
  };
};
