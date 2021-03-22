
#if os(macOS)
import Darwin.C
#elseif os(Linux)
import Glibc
#elseif os(Windows)
import ucrt
#endif

import ArArchiveKit

let fd = open("test.a", O_RDONLY)

let size = Int(lseek(fd, 0, SEEK_END))

lseek(fd, 0, SEEK_SET)

var uInt8Pointer = UnsafeMutablePointer<UInt8>.allocate(capacity: size)
let buf = UnsafeMutableRawBufferPointer.allocate(byteCount: size, alignment: MemoryLayout<UInt8>.alignment)

read(fd, buf.baseAddress, buf.count)

let bufferPointer = buf.bindMemory(to: UInt8.self)

let bytes = Array(bufferPointer)

let reader = try ArArchiveReader(archive: bytes)

for (header, file) in reader {
	print(header.name + ":")
	print()
	print(String(file))
	print()
}
