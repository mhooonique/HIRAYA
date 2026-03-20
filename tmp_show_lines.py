from pathlib import Path
p = Path(r'c:/Users/Christyn Dave/Documents/HIRAYA/lib/features/marketplace/screens/marketplace_screen.dart')
lines = p.read_text(encoding='utf-8').splitlines()
for i in range(915, 939):
    print(f"{i:4}: {lines[i-1]}")
