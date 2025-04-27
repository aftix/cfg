# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
path: name:
/*
bash
*/
''
  mkdir -p "$out/share/freshrss/extensions"
  cp -vLr "${path}" "$out/share/freshrss/extensions/xExtension-${name}"
''
