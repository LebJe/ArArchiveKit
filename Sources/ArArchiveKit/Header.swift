/// The `ar` header.
///
/// This header is placed atop the contents of a file in the archive to
/// provide information such as the size of the file, the file's name, it's permissions, etc.
public struct Header {
	/// The file's name. The name will be truncated to 16 characters.
	public let name: String

	/// The ID of the user the file belonged to when it was on the filesystem.
	public private(set) var userID: Int = 0

	/// The ID of the group the file belonged to when it was on the filesystem.
	public private(set) var groupID: Int = 0

	/// The permissions of the file.
	public private(set) var mode: UInt32 = 0o644

	/// The last time this file was modified.
	///
	/// Use `Int(myDate.timeIntervalSince1970)` to set `modificationTime` from a `Date`.
	public let modificationTime: Int

	/// The size if the file.
	///
	/// This variable is only set when reading in an archive header.
	public internal(set) var size: Int = 0

	public init(
		name: String,
		userID: Int = 0,
		groupID: Int = 0,
		mode: UInt32 = 0o644,
		modificationTime: Int
	) {
		self.name = name
		self.userID = userID
		self.groupID = groupID
		self.mode = mode
		self.modificationTime = modificationTime
	}
}
