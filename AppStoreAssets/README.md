# Untilia — App Store screenshots

The localized promotional screenshots are generated at the native 6.9-inch
portrait size: **1290 × 2796 px**, RGB PNG without transparency.

## Output

- `AppStore-6.9/fr/`: French App Store order
- `AppStore-6.9/en/`: English App Store order
- `AppStore-6.9/overview-fr.jpg`: French review sheet
- `AppStore-6.9/overview-en.jpg`: English review sheet
- `PremiumMontage-6.9/fr/01-premium-montage.png`: French multi-device hero
- `PremiumMontage-6.9/en/01-premium-montage.png`: English multi-device hero
- `AppStore-DynamicIsland-Large-1290x2796/fr/`: native French iPhone 15 Pro Max upload set
- `AppStore-DynamicIsland-Large-1290x2796/en/`: native English iPhone 15 Pro Max upload set
- `AppStore-DynamicIsland-Medium-1206x2622/fr/`: final French upload set
- `AppStore-DynamicIsland-Medium-1206x2622/en/`: final English upload set

The numbered filenames define the intended upload order.

The premium montage is designed to be used as the first screenshot, followed
by the simpler feature screenshots from the corresponding localized folder.

The original captures come from an iPhone 15 Pro Max. Their preferred target is
Media Manager → iPhone → **Dynamic Island (large display)**, where App Store
Connect explicitly accepts 1290 × 2796 px RGB PNGs. The medium-display export
is retained only as a fallback for its required 1206 × 2622 px well.

## Regenerate

```sh
/Users/olivier/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 \
  AppStoreAssets/scripts/build_promotional_screenshots.py
```

The source captures are read from `~/Downloads/IMG_8235.PNG` through
`~/Downloads/IMG_8244.PNG`. They are never modified.

The montage backdrop was generated specifically for Untilia, without text,
logos, devices, or interface elements. All visible app interfaces are composed
from the original screenshots.
