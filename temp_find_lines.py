from pathlib import Path
path = Path('temp_mobile_app/lib/main.dart')
lines = path.read_text(encoding='utf-8').splitlines()
for idx, line in enumerate(lines, start=1):
    if 'Text(_t("search"))' in line:
        print('search card label at line', idx)
    if 'Widget _buildPostTile' in line:
        print('buildPostTile at line', idx)
    if 'bottomNavigationBar' in line:
        print('bottomNavigationBar at line', idx)
    if 'BottomNavigationBarItem' in line and 'favorites' in line:
        print('favorites nav item at line', idx)
