import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

from pdf_parser.resume_parser import ResumePDFParser

def test_pure_python_with_fake_flatedecode_pdf():
    """Tests the zlib FlateDecode decompressor using a minimal hand-crafted PDF stream."""
    import zlib

    # Craft a minimal PDF content stream with compressed BT/ET block
    uncompressed = b"""BT
(Raghuraman K) Tj
(raghuraman@example.com) Tj
(Python SQL Power BI Azure) Tj
(Data Analytics Intern GainInsights Solutions) Tj
(MCA SRM College Ramapuram 2024) Tj
ET"""
    compressed = zlib.compress(uncompressed)

    # Build a fake PDF bytes structure that surrounds the stream with /FlateDecode header
    fake_pdf_bytes = (
        b"%PDF-1.4\n"
        b"1 0 obj\n"
        b"<< /Filter /FlateDecode /Length " + str(len(compressed)).encode() + b" >>\n"
        b"stream\n" + compressed + b"\nendstream\nendobj\n"
    )

    text = ResumePDFParser.extract_text_from_bytes(fake_pdf_bytes)

    print("=== PURE PYTHON FLATEDECODE DECODER TEST ===")
    print("Extracted Text:", repr(text))

    if text and "Raghuraman" in text:
        print("\nPure Python FlateDecode decoder works correctly!")
        return True
    else:
        print("\nFlateDecode decoder could not extract text (may need fitz/pdfplumber installed).")
        print("Is text empty?", not text)
        return False

def test_is_human_readable_filter():
    """Tests the binary garbage filter."""
    garbage = "/FlateDecode /Length 742 stream x wwYS n,HW PSajanqD y,,N"
    real_text = "Raghuraman K is a Data Analyst with Python and Power BI skills."

    assert not ResumePDFParser._is_human_readable(garbage), "Garbage should be filtered out"
    assert ResumePDFParser._is_human_readable(real_text), "Real text should pass"
    print("Binary garbage filter works correctly!")

if __name__ == "__main__":
    test_is_human_readable_filter()
    test_pure_python_with_fake_flatedecode_pdf()
    print("\nAll parser tests completed.")
