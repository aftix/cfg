# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
src:
/*
bash
*/
''
  mkdir -p "$out/share/freshrss/extensions"
  cp -vLr "${src}/xExtension-"* "$out/share/freshrss/extensions/"
''
