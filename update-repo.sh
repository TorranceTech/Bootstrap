#!/bin/sh
# Regenerates Packages, Packages.bz2, Packages.gz, and Release.
# Run after adding/updating any .deb in debs/.
# Requires: dpkg-deb (brew install dpkg), bzip2, gzip, shasum

set -e
cd "$(dirname "$0")"
. ./repo-config.sh

# ---- helpers ----
sha256() { shasum -a 256 "$1" | awk '{print $1}'; }
sha512() { shasum -a 512 "$1" | awk '{print $1}'; }
md5()    { md5 -q "$1" 2>/dev/null || md5sum "$1" | awk '{print $1}'; }
size()   { wc -c < "$1" | tr -d ' '; }

if ! command -v dpkg-deb >/dev/null 2>&1; then
    echo "ERROR: dpkg-deb not found. Install with: brew install dpkg" >&2
    exit 1
fi

# ---- generate Packages ----
echo "Generating Packages..."
> Packages

for deb in debs/*.deb; do
    [ -f "$deb" ] || continue

    dpkg-deb --field "$deb" > /tmp/_ctrl.txt

    # Append control fields
    cat /tmp/_ctrl.txt >> Packages
    printf "Filename: %s\n" "$deb"       >> Packages
    printf "Size: %s\n"     "$(size "$deb")" >> Packages
    printf "MD5sum: %s\n"   "$(md5 "$deb")"  >> Packages
    printf "SHA1: %s\n"     "$(shasum "$deb" | awk '{print $1}')" >> Packages
    printf "SHA256: %s\n"   "$(sha256 "$deb")" >> Packages

    # Inject depiction URL from package ID
    PKGID=$(grep '^Package:' /tmp/_ctrl.txt | awk '{print $2}')
    printf "Depiction: %s/depictions/%s.json\n" "$REPO_URL" "$PKGID" >> Packages
    printf "SileoDepiction: %s/depictions/%s.json\n" "$REPO_URL" "$PKGID" >> Packages
    printf "\n" >> Packages

    echo "  + $deb ($PKGID)"
done
rm -f /tmp/_ctrl.txt

# ---- compress ----
echo "Compressing..."
bzip2 -k -f Packages
gzip  -k -f Packages

# ---- generate Release ----
echo "Generating Release..."
# Flat repository. "Components: main" is REQUIRED: Sileo's RepoManager rejects
# any Release without a components key ("Could not parse release file").
cat > Release << EOF
Origin: $REPO_ORIGIN
Label: $REPO_LABEL
Suite: $REPO_SUITE
Version: 1.0
Codename: $REPO_CODENAME
Architectures: iphoneos-arm64 iphoneos-arm
Components: main
Description: $REPO_DESCRIPTION
MD5Sum:
 $(md5 Packages) $(size Packages) Packages
 $(md5 Packages.bz2) $(size Packages.bz2) Packages.bz2
 $(md5 Packages.gz) $(size Packages.gz) Packages.gz
SHA256:
 $(sha256 Packages) $(size Packages) Packages
 $(sha256 Packages.bz2) $(size Packages.bz2) Packages.bz2
 $(sha256 Packages.gz) $(size Packages.gz) Packages.gz
EOF

echo ""
echo "Done. Files updated: Packages, Packages.bz2, Packages.gz, Release"
echo "Commit and push to GitHub Pages to publish."
