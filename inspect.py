from pathlib import Path
text=Path('temp_mobile_app/lib/main.dart').read_text(encoding='utf-8')
start=text.index('" all\', text.index('AppLanguage.am'))
end=text.index('\n', start)
print(repr(text[start:end]))
