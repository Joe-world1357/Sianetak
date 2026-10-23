/**
 * Pure file rules: content sniffing and metadata removal. The client's declared MIME type and
 * file name are never trusted; the bytes decide.
 */
import { MediaContentType, MediaPurpose } from './media.entity';

export const ALLOWED_TYPES: Record<MediaPurpose, MediaContentType[]> = {
  [MediaPurpose.RequestPhoto]: ['image/jpeg', 'image/png'],
  [MediaPurpose.TechnicianDocument]: ['image/jpeg', 'image/png', 'application/pdf'],
};

const PNG_SIGNATURE = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);

export function sniffContentType(data: Buffer): MediaContentType | null {
  if (data.length >= 3 && data[0] === 0xff && data[1] === 0xd8 && data[2] === 0xff) {
    return 'image/jpeg';
  }
  if (data.length >= 8 && data.subarray(0, 8).equals(PNG_SIGNATURE)) return 'image/png';
  if (data.length >= 5 && data.subarray(0, 5).toString('latin1') === '%PDF-') {
    return 'application/pdf';
  }
  return null;
}

export class InvalidImageError extends Error {
  constructor() {
    super('Malformed image');
  }
}

/** Reads the EXIF orientation (1–8) from an APP1 payload, or null. */
function readExifOrientation(payload: Buffer): number | null {
  if (payload.length < 14 || payload.subarray(0, 6).toString('latin1') !== 'Exif\0\0') return null;
  const tiff = payload.subarray(6);
  const order = tiff.subarray(0, 2).toString('latin1');
  if (order !== 'II' && order !== 'MM') return null;
  const le = order === 'II';
  const u16 = (o: number) => (le ? tiff.readUInt16LE(o) : tiff.readUInt16BE(o));
  const u32 = (o: number) => (le ? tiff.readUInt32LE(o) : tiff.readUInt32BE(o));
  try {
    const ifd = u32(4);
    const count = u16(ifd);
    for (let i = 0; i < count; i++) {
      const entry = ifd + 2 + i * 12;
      if (u16(entry) === 0x0112) {
        const value = u16(entry + 8);
        return value >= 1 && value <= 8 ? value : null;
      }
    }
  } catch {
    return null;
  }
  return null;
}

/** A minimal APP1 segment holding only the orientation tag, so photos still display upright. */
function orientationSegment(orientation: number): Buffer {
  const payload = Buffer.alloc(32);
  payload.write('Exif\0\0', 0, 'latin1');
  payload.write('MM', 6, 'latin1');
  payload.writeUInt16BE(0x002a, 8);
  payload.writeUInt32BE(8, 10); // IFD0 offset from the TIFF header
  payload.writeUInt16BE(1, 14); // one entry
  payload.writeUInt16BE(0x0112, 16); // Orientation
  payload.writeUInt16BE(3, 18); // SHORT
  payload.writeUInt32BE(1, 20); // count
  payload.writeUInt16BE(orientation, 24);
  payload.writeUInt32BE(0, 28); // no next IFD
  const header = Buffer.from([0xff, 0xe1, 0, 0]);
  header.writeUInt16BE(payload.length + 2, 2);
  return Buffer.concat([header, payload]);
}

/** Markers kept before the image data: JFIF (APP0), ICC profile (APP2), Adobe (APP14). */
const KEEP_APP = new Set([0xe0, 0xe2, 0xee]);

/**
 * Removes EXIF (including GPS position, device and owner details), XMP, IPTC and comments from
 * a JPEG, keeping only what is needed to display it correctly. Throws InvalidImageError.
 */
export function stripJpegMetadata(data: Buffer): Buffer {
  if (data.length < 4 || data[0] !== 0xff || data[1] !== 0xd8) throw new InvalidImageError();
  const out: Buffer[] = [data.subarray(0, 2)];
  let orientation: number | null = null;
  let orientationInsertAt = 1;
  let offset = 2;
  while (offset < data.length) {
    if (data[offset] !== 0xff) throw new InvalidImageError();
    let marker = data[offset + 1];
    while (marker === 0xff && offset + 2 < data.length) {
      offset += 1; // fill bytes
      marker = data[offset + 1];
    }
    if (marker === undefined) throw new InvalidImageError();
    if (marker === 0xd9) {
      out.push(data.subarray(offset, offset + 2));
      break;
    }
    if (marker >= 0xd0 && marker <= 0xd7) throw new InvalidImageError();
    if (offset + 4 > data.length) throw new InvalidImageError();
    const length = data.readUInt16BE(offset + 2);
    if (length < 2 || offset + 2 + length > data.length) throw new InvalidImageError();
    const segmentEnd = offset + 2 + length;
    if (marker === 0xda) {
      // Start of scan: the rest is entropy-coded image data, copied unchanged.
      out.push(data.subarray(offset));
      break;
    }
    const isApp = marker >= 0xe0 && marker <= 0xef;
    if (marker === 0xe1) {
      orientation ??= readExifOrientation(data.subarray(offset + 4, segmentEnd));
    } else if ((isApp && !KEEP_APP.has(marker)) || marker === 0xfe) {
      // dropped: other APPn metadata and comments
    } else {
      out.push(data.subarray(offset, segmentEnd));
      if (marker === 0xe0) orientationInsertAt = out.length;
    }
    offset = segmentEnd;
  }
  if (orientation !== null && orientation !== 1) {
    out.splice(orientationInsertAt, 0, orientationSegment(orientation));
  }
  return Buffer.concat(out);
}

const PNG_DROP = new Set(['tEXt', 'zTXt', 'iTXt', 'eXIf', 'tIME']);

/** Removes text, EXIF and timestamp chunks from a PNG. Throws InvalidImageError. */
export function stripPngMetadata(data: Buffer): Buffer {
  if (!data.subarray(0, 8).equals(PNG_SIGNATURE)) throw new InvalidImageError();
  const out: Buffer[] = [PNG_SIGNATURE];
  let offset = 8;
  let sawEnd = false;
  while (offset + 12 <= data.length) {
    const length = data.readUInt32BE(offset);
    const type = data.subarray(offset + 4, offset + 8).toString('latin1');
    const end = offset + 12 + length;
    if (!/^[A-Za-z]{4}$/.test(type) || end > data.length) throw new InvalidImageError();
    if (!PNG_DROP.has(type)) out.push(data.subarray(offset, end));
    offset = end;
    if (type === 'IEND') {
      sawEnd = true;
      break;
    }
  }
  if (!sawEnd) throw new InvalidImageError();
  return Buffer.concat(out);
}

/** Returns the bytes to store: images without metadata, PDFs unchanged. */
export function sanitizeUpload(type: MediaContentType, data: Buffer): Buffer {
  if (type === 'image/jpeg') return stripJpegMetadata(data);
  if (type === 'image/png') return stripPngMetadata(data);
  return data;
}
