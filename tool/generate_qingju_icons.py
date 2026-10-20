"""按原有尺寸生成青橘图标；不触碰代码与平台配置。需要 Pillow。"""
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]

def icon(size):
    scale = 4
    n = max(size) * scale
    im = Image.new('RGB', (n, n), '#edf5e8')
    d = ImageDraw.Draw(im)
    def box(a, b, c, e):
        return tuple(int(v * n) for v in (a, b, c, e))
    d.rounded_rectangle(box(.04,.04,.96,.96), radius=int(n*.2), fill='#295c39')
    d.ellipse(box(.21,.29,.79,.85), fill='#f8ad38')
    d.ellipse(box(.28,.35,.72,.78), fill='#ffd475')
    d.ellipse(box(.44,.15,.78,.32), fill='#a4ce72')
    d.line([(int(n*.5),int(n*.32)),(int(n*.57),int(n*.21))], fill='#a4ce72', width=max(1,int(n*.035)))
    d.arc(box(.33,.4,.67,.73), 35, 300, fill='#fff7df', width=max(1,int(n*.035)))
    return im.resize(size, Image.Resampling.LANCZOS)

def main():
    paths = set()
    for root in ['ios/Runner/Assets.xcassets', 'macos/Runner/Assets.xcassets']:
        for p in (ROOT/root).rglob('*.png'):
            if 'AppIcon' in str(p.parent):
                paths.add(p)
    for p in (ROOT/'android/app/src/main/res').rglob('*.png'):
        if p.name.startswith('ic_launcher'):
            paths.add(p)
    paths.update((ROOT/'assets/images').glob('icon_*preview.png'))
    for p in paths:
        with Image.open(p) as source:
            size = source.size
        icon(size).save(p)
    ico = ROOT/'windows/runner/resources/app_icon.ico'
    icon((256,256)).save(ico, format='ICO', sizes=[(16,16),(32,32),(48,48),(64,64),(128,128),(256,256)])
    for p in (ROOT/'linux').rglob('*.png'):
        if 'icon' in p.name or 'fluxdo' in p.name:
            with Image.open(p) as source:
                size=source.size
            icon(size).save(p)
    # Android 8+ 使用矢量前景，不能只替换旧版 PNG。
    vector = '''<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="108dp" android:height="108dp" android:viewportWidth="108" android:viewportHeight="108"><path android:fillColor="#F8AD38" android:pathData="M54,30 A28,28 0,1 0,54 86 A28,28 0,1 0,54 30"/><path android:fillColor="#A4CE72" android:pathData="M52,32 Q54,12 78,20 Q74,36 52,32"/><path android:fillColor="#FFD475" android:pathData="M54,37 A21,21 0,1 0,54 79 A21,21 0,1 0,54 37"/></vector>'''
    for folder in ['drawable', 'drawable-night']:
        for p in (ROOT/'android/app/src/main/res'/folder).glob('ic_launcher*.xml'):
            p.read_text(encoding='utf-8')
            p.write_text(vector, encoding='utf-8')
    icon((256,256)).save(ROOT/'linux/runner/qingju.png')
    print(f'已生成 {len(paths)} 份平台 PNG、Android 矢量前景和 Windows ICO')

if __name__ == '__main__':
    main()
