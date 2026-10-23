import { jpegWithMetadata, pdfDocument, pngWithMetadata } from '../../test/fixtures/images';
import {
  InvalidImageError,
  sanitizeUpload,
  sniffContentType,
  stripJpegMetadata,
  stripPngMetadata,
} from './media.rules';

const latin = (b: Buffer) => b.toString('latin1');

describe('sniffContentType', () => {
  it('recognises JPEG, PNG and PDF by their bytes', () => {
    expect(sniffContentType(jpegWithMetadata())).toBe('image/jpeg');
    expect(sniffContentType(pngWithMetadata())).toBe('image/png');
    expect(sniffContentType(pdfDocument())).toBe('application/pdf');
  });

  it('rejects anything else, whatever its name claims', () => {
    expect(sniffContentType(Buffer.from('<svg onload="alert(1)"></svg>'))).toBeNull();
    expect(sniffContentType(Buffer.from('GIF89a'))).toBeNull();
    expect(sniffContentType(Buffer.from([0x4d, 0x5a, 0x90, 0x00]))).toBeNull();
    expect(sniffContentType(Buffer.alloc(0))).toBeNull();
  });
});

describe('stripJpegMetadata', () => {
  it('removes EXIF/GPS, IPTC and comments but keeps image data and orientation', () => {
    const out = stripJpegMetadata(jpegWithMetadata(6));
    expect(latin(out)).not.toContain('GPS24.0889N');
    expect(latin(out)).not.toContain('IPTC owner');
    expect(latin(out)).not.toContain('camera owner comment');
    expect(latin(out)).toContain('JFIF');
    // Minimal EXIF segment with only Orientation = 6.
    const exifAt = out.indexOf(Buffer.from('Exif\0\0', 'latin1'));
    expect(exifAt).toBeGreaterThan(0);
    expect(out.readUInt16BE(exifAt + 6 + 8 + 2)).toBe(0x0112);
    expect(out.readUInt16BE(exifAt + 6 + 8 + 10)).toBe(6);
    // Scan data and end marker survive untouched.
    expect(out.subarray(-7)).toEqual(Buffer.from([0x12, 0x34, 0xff, 0x00, 0x56, 0xff, 0xd9]));
  });

  it('drops the EXIF segment entirely when orientation is normal', () => {
    expect(latin(stripJpegMetadata(jpegWithMetadata(1)))).not.toContain('Exif');
  });

  it('rejects truncated or malformed JPEGs', () => {
    const jpeg = jpegWithMetadata();
    expect(() => stripJpegMetadata(jpeg.subarray(0, 30))).toThrow(InvalidImageError);
    expect(() => stripJpegMetadata(Buffer.from([0xff, 0xd8, 0x00, 0x01]))).toThrow(
      InvalidImageError,
    );
  });
});

describe('stripPngMetadata', () => {
  it('removes text and EXIF chunks and keeps image chunks', () => {
    const out = stripPngMetadata(pngWithMetadata());
    expect(latin(out)).not.toContain('Secret Owner');
    expect(latin(out)).not.toContain('GPS-location');
    expect(latin(out)).toContain('IHDR');
    expect(latin(out)).toContain('IDAT');
    expect(latin(out.subarray(-8, -4))).toBe('IEND');
  });

  it('rejects a PNG without an end chunk', () => {
    const png = pngWithMetadata();
    expect(() => stripPngMetadata(png.subarray(0, png.length - 12))).toThrow(InvalidImageError);
  });
});

describe('sanitizeUpload', () => {
  it('leaves PDFs unchanged', () => {
    const pdf = pdfDocument();
    expect(sanitizeUpload('application/pdf', pdf)).toEqual(pdf);
  });
});
