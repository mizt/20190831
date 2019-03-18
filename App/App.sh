#!/bin/bash
dir=$(cd $(dirname $0)&&pwd)
cd $dir

App="App"

mkdir -p ${App}.app/Contents/{MacOS,Resources}

cat > ${App}.app/Contents/Info.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
	<dict>
		<key>CFBundleExecutable</key>
		<string>${App}</string>
	</dict>
</plist>
EOF

if [ -e ${App} ]; then
	mv ${App} ${App}.app/Contents/MacOS/
	chmod +x ${App}.app/Contents/MacOS/${App}
fi