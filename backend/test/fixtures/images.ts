/** Small synthetic files for upload tests. Structure is valid; pixel data is a placeholder. */
import { crc32 } from 'node:zlib';

const segment = (marker: number, payload: Buffer) => {
  const header = Buffer.from([0xff, marker, 0, 0]);
  header.writeUInt16BE(payload.length + 2, 2);
  return Buffer.concat([header, payload]);
};

/** EXIF APP1 payload (big-endian) with Orientation and a GPS IFD pointer plus GPS data. */
function exifPayload(orientation: number) {
  const tiff = Buffer.alloc(64);
  tiff.write('MM', 0, 'latin1');
  tiff.writeUInt16BE(0x2a, 2);
  tiff.writeUInt32BE(8, 4);
  tiff.writeUInt16BE(2, 8); // two IFD0 entries
  tiff.writeUInt16BE(0x0112, 10);
  tiff.writeUInt16BE(3, 12);
  tiff.writeUInt32BE(1, 14);
  tiff.writeUInt16BE(orientation, 18);
  tiff.writeUInt16BE(0x8825, 22); // GPSInfo IFD pointer
  tiff.writeUInt16BE(4, 24);
  tiff.writeUInt32BE(1, 26);
  tiff.writeUInt32BE(38, 30);
  tiff.writeUInt32BE(0, 34);
  tiff.write('GPS24.0889N32.8998E', 38, 'latin1');
  return Buffer.concat([Buffer.from('Exif\0\0', 'latin1'), tiff]);
}

export function jpegWithMetadata(orientation = 6) {
  return Buffer.concat([
    Buffer.from([0xff, 0xd8]),
    segment(0xe0, Buffer.from('JFIF\0\x01\x01\0\0\x01\0\x01\0\0', 'latin1')),
    segment(0xe1, exifPayload(orientation)),
    segment(0xed, Buffer.from('Photoshop 3.0\0IPTC owner name', 'latin1')),
    segment(0xfe, Buffer.from('camera owner comment', 'latin1')),
    segment(0xdb, Buffer.alloc(65, 1)),
    segment(0xda, Buffer.from([1, 1, 0, 0, 63, 0])),
    Buffer.from([0x12, 0x34, 0xff, 0x00, 0x56]),
    Buffer.from([0xff, 0xd9]),
  ]);
}

const chunk = (type: string, data: Buffer) => {
  const len = Buffer.alloc(4);
  len.writeUInt32BE(data.length);
  const body = Buffer.concat([Buffer.from(type, 'latin1'), data]);
  const crc = Buffer.alloc(4);
  crc.writeUInt32BE(crc32(body));
  return Buffer.concat([len, body, crc]);
};

export function pngWithMetadata() {
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(1, 0);
  ihdr.writeUInt32BE(1, 4);
  ihdr[8] = 8;
  ihdr[9] = 2;
  return Buffer.concat([
    Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    chunk('IHDR', ihdr),
    chunk('tEXt', Buffer.from('Author\0Secret Owner', 'latin1')),
    chunk('eXIf', Buffer.from('MM\0*GPS-location', 'latin1')),
    chunk('IDAT', Buffer.from([0x78, 0x9c, 0x63, 0, 0, 0, 1, 0, 1])),
    chunk('IEND', Buffer.alloc(0)),
  ]);
}

export function pdfDocument() {
  return Buffer.from('%PDF-1.4\n1 0 obj<<>>endobj\ntrailer<<>>\n%%EOF\n', 'latin1');
}
