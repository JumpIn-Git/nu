import re

import pdfplumber
import tomli_w


def extract_to_toml_indexed(pdf_path):
    indexed_data = {}

    # Matches the date format: DD/MM/YYYY
    date_pattern = re.compile(r"(\d{2}/\d{2}/2026)")
    with pdfplumber.open(pdf_path) as pdf:
        for page in pdf.pages:
            print(page.lines)
            text = page.extract_text()
            if not text:
                continue

            for line in text.split("\n"):
                match = date_pattern.search(line)
                if match:
                    parts = line.split()
                    if len(parts) >= 9:
                        date_key = parts[0]  # Use the date as the unique ID
                        indexed_data[date_key] = {
                            "hijri": f"{parts[1]} {parts[2]}",  # Includes month label like (Raj)
                            "fajr": parts[3],
                            "sunrise": parts[4],
                            "dhuhr": parts[5],
                            "asr": parts[6],
                            "maghrib": parts[7],
                            "isha": parts[8],
                        }
    with open("prayer_times.toml", "wb") as f:
        tomli_w.dump(indexed_data, f)

    print(f"Success! Indexed {len(indexed_data)} dates into TOML.")


extract_to_toml_indexed("prayer_times.pdf")
