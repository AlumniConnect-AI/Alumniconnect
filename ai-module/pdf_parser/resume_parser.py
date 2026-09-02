import re
import io
import zlib
import unicodedata


class ResumePDFParser:
    """Robust PDF Resume text extractor. Multi-strategy: PyMuPDF → pdfplumber → pypdf → zlib fallback."""

    @staticmethod
    def extract_text_from_bytes(pdf_bytes: bytes) -> str:
        """Extract raw text from PDF bytes across all pages."""
        if not pdf_bytes or len(pdf_bytes) < 10:
            return ""

        text = ""

        # Strategy 1: Try PyMuPDF (fitz) — best quality, handles Canva/LinkedIn/ATS resumes
        try:
            import fitz  # PyMuPDF
            doc = fitz.open(stream=pdf_bytes, filetype="pdf")
            page_texts = []
            for page in doc:
                # Use detailed text extraction with layout preserved
                raw = page.get_text("text", flags=fitz.TEXT_PRESERVE_WHITESPACE | fitz.TEXT_DEHYPHENATE)
                if raw:
                    page_texts.append(raw)
            doc.close()
            text = "\n".join(page_texts)
        except Exception:
            text = ""

        # Strategy 2: Try pdfplumber — good for complex layouts
        if len(text.strip()) < 30:
            try:
                import pdfplumber
                with pdfplumber.open(io.BytesIO(pdf_bytes)) as pdf:
                    page_texts = []
                    for page in pdf.pages:
                        raw = page.extract_text(x_tolerance=3, y_tolerance=3)
                        if raw:
                            page_texts.append(raw)
                    text = "\n".join(page_texts)
            except Exception:
                pass

        # Strategy 3: Try pypdf / PyPDF2
        if len(text.strip()) < 30:
            try:
                from pypdf import PdfReader
                reader = PdfReader(io.BytesIO(pdf_bytes))
                page_texts = [page.extract_text() or "" for page in reader.pages]
                text = "\n".join(page_texts)
            except Exception:
                try:
                    from PyPDF2 import PdfReader
                    reader = PdfReader(io.BytesIO(pdf_bytes))
                    page_texts = [page.extract_text() or "" for page in reader.pages]
                    text = "\n".join(page_texts)
                except Exception:
                    pass

        # Strategy 4: Pure Python with FlateDecode (zlib) decompression — last resort
        if len(text.strip()) < 30:
            try:
                text = ResumePDFParser._pure_python_pdf_decoder(pdf_bytes)
            except Exception:
                pass

        cleaned = ResumePDFParser.clean_text(text)

        # Final guard: if still looks like binary garbage, return empty string (not dummy data)
        if cleaned and not ResumePDFParser._is_human_readable(cleaned):
            return ""

        return cleaned

    @staticmethod
    def _pure_python_pdf_decoder(pdf_bytes: bytes) -> str:
        """
        Decompresses FlateDecode (zlib) PDF content streams and extracts
        human-readable text from BT...ET operator blocks.
        Zero-dependency fallback when fitz/pdfplumber/pypdf are absent.
        """
        decompressed_texts = []

        flate_block_pattern = re.compile(
            rb'(/FlateDecode[\s\S]{1,500}?)stream\r?\n([\s\S]*?)\r?\nendstream',
            re.DOTALL
        )

        for match in flate_block_pattern.finditer(pdf_bytes):
            stream_data = match.group(2)
            try:
                decompressed = zlib.decompress(stream_data)
                decoded = decompressed.decode('latin-1', errors='ignore')
                text_from_block = ResumePDFParser._extract_text_from_pdf_stream(decoded)
                if text_from_block.strip():
                    decompressed_texts.append(text_from_block)
            except zlib.error:
                pass
            except Exception:
                pass

        if decompressed_texts:
            return "\n".join(decompressed_texts)

        # Final fallback: extract long printable ASCII runs
        raw_str = pdf_bytes.decode('latin-1', errors='ignore')
        printable_runs = re.findall(r'[A-Za-z][A-Za-z0-9\s.,@\-+:;\(\)\/\'\"\[\]!?%#&_=]{15,}', raw_str)
        return "\n".join(printable_runs)

    @staticmethod
    def _extract_text_from_pdf_stream(stream_content: str) -> str:
        """Extracts readable text from a decompressed PDF content stream."""
        text_parts = []

        bt_et_blocks = re.findall(r'BT([\s\S]*?)ET', stream_content)

        for block in bt_et_blocks:
            # Tj — simple string: (text) Tj
            tj_matches = re.findall(r'\(([^)]*)\)\s*Tj', block)
            text_parts.extend(tj_matches)

            # TJ — array of strings: [(text1)(text2)] TJ
            tj_array_matches = re.findall(r'\[([^\]]*)\]\s*TJ', block)
            for arr in tj_array_matches:
                arr_strings = re.findall(r'\(([^)]*)\)', arr)
                text_parts.extend(arr_strings)

            # Single-quote operator: (text) '
            quote_matches = re.findall(r"\(([^)]*)\)\s*'", block)
            text_parts.extend(quote_matches)

        clean_parts = []
        for part in text_parts:
            part = part.replace(r'\n', '\n').replace(r'\r', '\r')
            part = part.replace(r'\t', ' ').replace(r'\\', '\\')
            part = part.replace(r'\(', '(').replace(r'\)', ')')
            printable_ratio = sum(1 for c in part if 32 <= ord(c) <= 126) / max(len(part), 1)
            if printable_ratio > 0.7 and len(part.strip()) > 0:
                clean_parts.append(part.strip())

        return " ".join(clean_parts)

    @staticmethod
    def _is_human_readable(text: str) -> bool:
        """Returns True if text contains enough human-readable content."""
        if not text or len(text) < 10:
            return False

        # Reject raw PDF structure keywords
        pdf_keywords = [r'/FlateDecode', r'/DecodeParms', r'/XRef', r'/ObjStm', r'/MediaBox', r'/Catalog', r'endstream', r'endobj']
        for kw in pdf_keywords:
            if re.search(kw, text, re.IGNORECASE):
                return False

        printable = sum(1 for c in text if 32 <= ord(c) <= 126 or c in '\n\r\t')
        ratio = printable / len(text)
        if ratio < 0.75:
            return False

        # Must contain at least one real word (3+ consecutive alphabetic chars)
        return bool(re.search(r'[A-Za-z]{3,}', text))

    @staticmethod
    def clean_text(text: str) -> str:
        """Cleans and normalizes extracted resume text while preserving readability."""
        if not text:
            return ""

        # Normalize unicode characters (handles special quotes, dashes, bullets, etc.)
        text = unicodedata.normalize('NFKC', text)

        # Replace common unicode bullets/dashes with ASCII equivalents
        text = text.replace('\u2022', '-').replace('\u2013', '-').replace('\u2014', '-')
        text = text.replace('\u2018', "'").replace('\u2019', "'")
        text = text.replace('\u201c', '"').replace('\u201d', '"')
        text = text.replace('\ufb01', 'fi').replace('\ufb02', 'fl')  # ligatures

        # Remove non-printable chars except line breaks and tabs
        cleaned = re.sub(r'[^\x20-\x7E\n\r\t\u00C0-\u024F]', ' ', text)

        # Standardize newlines
        cleaned = cleaned.replace('\r\n', '\n').replace('\r', '\n')

        # Unescape PDF escaped parens
        cleaned = cleaned.replace(r'\(', '(').replace(r'\)', ')')

        # Collapse multiple inline spaces (but preserve newlines)
        cleaned = re.sub(r'[ \t]+', ' ', cleaned)

        # Collapse excessive blank lines (max 2 consecutive newlines)
        cleaned = re.sub(r'\n{3,}', '\n\n', cleaned)

        # Remove lines that are just single characters or PDF artifacts
        lines = cleaned.split('\n')
        lines = [l for l in lines if len(l.strip()) > 1 or l.strip() == '']
        cleaned = '\n'.join(lines)

        return cleaned.strip()
