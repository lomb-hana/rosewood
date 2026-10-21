set -e
cd /workspace/rosewood
rm -rf build && mkdir -p build/web build/windows
godot --headless --path . --export-release Web build/web/index.html >/dev/null 2>&1
godot --headless --path . --export-release Windows build/windows/Rosewood.exe >/dev/null 2>&1
rm -f build/web/*.import /workspace/rosewood-windows.zip
python3 -c "import zipfile;z=zipfile.ZipFile('/workspace/rosewood-windows.zip','w',zipfile.ZIP_DEFLATED);z.write('build/windows/Rosewood.exe','Rosewood/Rosewood.exe')"
ID='-c user.name=lomb-hana -c user.email=lomb-hana@users.noreply.github.com'
[ -d /tmp/rws ] || git clone -q -b source https://github.com/lomb-hana/rosewood /tmp/rws
[ -d /tmp/rwp ] || git clone -q -b main https://github.com/lomb-hana/rosewood /tmp/rwp
cp -r project.godot main.tscn *.gd export_presets.cfg .gitignore README.md maps tools /tmp/rws/
cd /tmp/rws && git add -A && git $ID commit -qm "$1" && git push -q origin source
cp /workspace/rosewood/build/web/* /tmp/rwp/ && cd /tmp/rwp && git add -A && git $ID commit -qm "Web build: $1" && git push -q origin main
c=$(git rev-parse --short HEAD)
for i in $(seq 1 40); do st=$(gh api repos/lomb-hana/rosewood/pages/builds/latest --jq '.status+" "+.commit[0:7]'); echo "$st" | grep -q "built $c" && break; sleep 10; done; echo "$st"
