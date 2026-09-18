"""Write the AltStore source manifest that lets the phone update Jo over the air.

Usage: make_altstore_source.py <build_number> <ipa_path> <output_path>
"""

import json
import os
import sys
from datetime import date

REPO = "Teneeduu/HelloWorldiOS"
BUNDLE_ID = "com.example.helloworld"
ICON_URL = (
    f"https://raw.githubusercontent.com/{REPO}/main/"
    "Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png"
)

build = sys.argv[1]
ipa_path = sys.argv[2]
out_path = sys.argv[3]

description = (
    "Jo 是一个自用的个人助手：彩色的 Hello world 主屏、相册幻灯片背景、"
    "循环播放的音乐、每日名言，以及照着 jo-app 搬过来的今日／本周／目标规划。"
)

source = {
    "name": "Jo",
    "identifier": "com.example.jo.source",
    "subtitle": "Teneeduu 的自建 App 源",
    "description": description,
    "iconURL": ICON_URL,
    "website": f"https://github.com/{REPO}",
    "apps": [
        {
            "name": "Jo",
            "bundleIdentifier": BUNDLE_ID,
            "developerName": "Teneeduu",
            "subtitle": "规划、音乐、照片和每日名言",
            "localizedDescription": description,
            "iconURL": ICON_URL,
            "tintColor": "4340D9",
            "category": "productivity",
            "screenshotURLs": [],
            "versions": [
                {
                    "version": f"1.0.{build}",
                    "buildVersion": build,
                    "date": date.today().isoformat(),
                    "localizedDescription": f"build {build}",
                    "downloadURL": (
                        f"https://github.com/{REPO}/releases/download/"
                        f"build-{build}/HelloWorld-unsigned.ipa"
                    ),
                    "size": os.path.getsize(ipa_path),
                    "minOSVersion": "16.0",
                }
            ],
            "appPermissions": {},
        }
    ],
    "news": [],
}

with open(out_path, "w", encoding="utf-8") as f:
    json.dump(source, f, ensure_ascii=False, indent=2)

print(f"wrote {out_path} for build {build} ({source['apps'][0]['versions'][0]['size']} bytes)")
