# roothide Bootstrap — palera1n port

[![GitHub stars](https://img.shields.io/github/stars/TorranceTech/Bootstrap?style=social)](https://github.com/TorranceTech/Bootstrap/stargazers)

This fork ports `bootstrapd` from [roothide Bootstrap](https://github.com/roothide/Bootstrap) to run natively on **palera1n**, enabling iPadOS/iOS 16–18 support on A8–A11 devices without roothide.

> **This is not two jailbreaks stacked.** palera1n handles the kernel layer. Our `bootstrapd` is a pure userland daemon that runs inside palera1n's environment.

---

## palera1n Install Guide (iPadOS/iOS 16–18)

### Requirements

| What | Version |
|---|---|
| Device | A8–A11 (iPhone 6–X, iPad 5th–7th gen) |
| iOS / iPadOS | 16.0 – 18.x |
| Jailbreak | [palera1n](https://github.com/palera1n/palera1n) 2.x |
| Mac | macOS 12+ with Xcode 14+ |

### Step 1 — Jailbreak with palera1n

```sh
# Install palera1n on Mac
brew install palera1n

# Jailbreak (rootless mode)
palera1n -l

# Follow the on-screen DFU instructions for your device
```

After the jailbreak completes, open the **palera1n** app on your device and tap **Install** to set up Sileo.

### Step 2 — Add the Sileo repository

In Sileo: **Sources → Edit → +** and add:

```
https://torrancetech.github.io/Bootstrap/repo
```

Search for **"Bootstrap Daemon (palera1n)"** and install.

The `postinst` script will:
- Copy `bootstrapd` to `/var/jb/basebin/`
- Load the LaunchDaemon → auto-starts on every boot

### Step 3 — Verify

```sh
# SSH into your device and check:
launchctl list | grep bootstrapd
# Should show: com.palera1n.bootstrapd
```

---

## Building from Source

### Prerequisites

```sh
# Standard Theos (NOT roothide's fork)
bash -c "$(curl -fsSL https://raw.githubusercontent.com/theos/theos/master/bin/install-theos)"

# dpkg for packaging
brew install dpkg
```

### Clone

```sh
git clone --recurse-submodules https://github.com/TorranceTech/Bootstrap
cd Bootstrap/basebin
```

If the submodule doesn't check out the right branch:

```sh
cd basebin
git remote add torrancetech https://github.com/TorranceTech/Bootstrap-basebin
git fetch torrancetech
git checkout -b feature/ios18-palera1n-support torrancetech/feature/ios18-palera1n-support
cd ..
```

### Build

```sh
# Compile libcommon + bootstrapd
cd basebin/common   && make clean all PALERA1N=1 && cd -
cd basebin/bootstrapd

# Build binary + create .deb
make package-palera1n VERSION=1.0.0
# Output: packages/io.github.torrancetech.bootstrapd-palera1n_1.0.0_iphoneos-arm64.deb
```

### Publish to repo

```sh
cp basebin/bootstrapd/packages/*.deb repo/debs/
cd repo && ./update-repo.sh
git add repo/ && git commit -m "release: bootstrapd-palera1n 1.0.0" && git push
```

---

## Architecture

```
palera1n (kernel layer)
└── checkm8 exploit → kernel patches → /var/jb/ symlink

bootstrapd (userland daemon)
└── Mach IPC server: com.roothide.bootstrapd-0070616C65726131
    ├── SSH management
    ├── JIT enabler
    └── Sandbox extension management
```

**What we changed vs roothide:**
- `jbroot()` shim: replaces UUID-randomized paths with fixed `/var/jb/`
- `jbrand()` shim: returns fixed constant `0x70616C65726131` ("palera1" ASCII)
- `jailbreakd` excluded: requires roothide kernel primitives, not available on palera1n
- Build system: uses standard Theos (`rootless` scheme) instead of roothide's Theos fork

---

## Compatibility

| Feature | Status |
|---|---|
| JIT (DolphiniOS, UTM, PPSSPP) | Works via bootstrapd IPC |
| SSH server management | Works |
| Mach IPC | Works — tested on iPad 7th gen / iPadOS 18.7.9 / palera1n 2.3 |
| Tweak injection (bsctl) | In progress |
| roothide tweaks | Not compatible (different kernel ABI) |

---

## FAQ

**Can I use roothide tweaks?**
No. roothide tweaks require the roothide kernel hook (`jailbreakd`). Standard palera1n tweaks work normally.

**Does this work on iPhone?**
Any A8–A11 device supported by palera1n: iPhone 6, 6s, 7, 8, X, SE (1st gen).

**Is this safe?**
We only run `bootstrapd` which is userland. palera1n does the kernel work. Same risk profile as any palera1n jailbreak.

---

## Contributing

PRs welcome. The palera1n compat layer lives in `basebin/palera1n_compat/`. The key files:

- `roothide.h` — `jbroot()`/`jbrand()` shims
- `sandbox_ext_palera1n.m` — stub for `generate_sandbox_extensions()`
- `layout.palera1n/` — package layout (LaunchDaemon, postinst/prerm)

---

## Credits

Port to palera1n by [TorranceTech](https://github.com/TorranceTech).

Original roothide Bootstrap by [roothide](https://github.com/roothide) and contributors:

- absidue · akusio · Alfie · Amy While · Barron · BomberFish · bswbw · Capt Inc · CKatri
- Clarity · Cryptic · dxcool223x · Dhinakg · DuyKhanhTran · dleovl · Elias Sfeir · Ellie
- EquationGroups · Évelyne · GeoSnOw · G3n3sis · hayden · Huy Nguyen · iAdam1n · iarrays
- iDownloadBlog · iExmo · iRaMzi · Jonathan · Kevin · kirb · laileld · Leptos · limneos
- Lightmann · Linus Henze · MasterMike · Misty · Muirey03 · Nathan · Nebula · niceios
- Nightwind · Nick Chan · nzhaonan · Oliver Tzeng · omrkujman · opa334 · onejailbreak
- Phuc Do · PoomSmart · ProcursusTeam · roothide · Sam Bingner · Shadow- · Snail
- SquidGesture · sourcelocation · SeanIsTethered · TheosTeam · tigisoftware · tihmstar
- xina520 · xybp888 · xsf1re · yandevelop · YourRepo
- And the community, for giving insightful feedback and support.

**WARNING:** By using this software, you take full responsibility for what you do with it. Any unofficial modifications to your device may cause irreparable damage.
