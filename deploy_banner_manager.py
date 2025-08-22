#!/usr/bin/env python3
"""
Deploy Banner Manager
This script injects language-specific banners into HTML files during GitHub Actions deployment.
"""

import os
import re
import argparse
from bs4 import BeautifulSoup

def read_banner_template(language='en'):
    """Read banner template for the specified language"""
    filename = "banner_component.html"  # Default English
    if language == 'es':
        filename = "banner_component_es.html"
    elif language == 'fr':
        filename = "banner_component_fr.html"
    
    try:
        with open(filename, 'r', encoding='utf-8') as f:
            return f.read()
    except FileNotFoundError:
        print(f"Banner template {filename} not found!")
        return ""

def detect_language(html_content):
    """Detect the language of the HTML content based on common language patterns"""
    # Spanish patterns
    es_patterns = [
        r'\bEspaño\b', r'\bRecursos\b', r'\bSobre\b', r'\bNuestro Enfoque\b', 
        r'\bNuestro Trabajo\b', r'\bÚnete\b', r'\bContacto\b', r'\bde la\b'
    ]
    
    # French patterns
    fr_patterns = [
        r'\bFrançais\b', r'\bRessources\b', r'\bÀ propos\b', r'\bNotre approche\b', 
        r'\bNotre travail\b', r'\bRejoignez-nous\b', r'\bContact\b', r'\bde la\b'
    ]
    
    # Check for Spanish patterns
    for pattern in es_patterns:
        if re.search(pattern, html_content):
            return 'es'
    
    # Check for French patterns
    for pattern in fr_patterns:
        if re.search(pattern, html_content):
            return 'fr'
    
    # Default to English
    return 'en'

def inject_banner(html_content, banner_html):
    """Insert banner at the top of the body tag"""
    soup = BeautifulSoup(html_content, 'html.parser')
    body = soup.body
    
    if not body:
        return html_content
    
    # Create banner element
    banner_soup = BeautifulSoup(banner_html, 'html.parser')
    banner_div = banner_soup.find('div')
    
    # Insert at the beginning of body
    body.insert(0, banner_div)
    
    return str(soup)

def process_directory(directory):
    """Process all HTML files in the given directory and subdirectories"""
    count = 0
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.html'):
                file_path = os.path.join(root, file)
                
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        content = f.read()
                    
                    # Skip if already has a banner
                    if 'lacuna-banner' in content:
                        continue
                    
                    # Detect language
                    lang = detect_language(content)
                    
                    # Get appropriate banner
                    banner = read_banner_template(lang)
                    
                    if banner:
                        # Inject banner
                        new_content = inject_banner(content, banner)
                        
                        # Write back to file
                        with open(file_path, 'w', encoding='utf-8') as f:
                            f.write(new_content)
                        
                        count += 1
                        print(f"Added {lang} banner to {file_path}")
                except Exception as e:
                    print(f"Error processing {file_path}: {str(e)}")
    
    print(f"Processed {count} files")

def main():
    parser = argparse.ArgumentParser(description="Deploy banners to HTML files")
    parser.add_argument("--directory", default="_site", help="Directory to process")
    args = parser.parse_args()
    
    process_directory(args.directory)

if __name__ == "__main__":
    main()
