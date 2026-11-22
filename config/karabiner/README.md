# Configs for Karabiner


## Setup

`install.py` copies `karabiner.json` to `~/.config/karabiner/karabiner.json` if that file does not exist yet
(it is copied, not symlinked: Karabiner-Elements replaces a symlinked `karabiner.json` with a copy).

To overwrite an existing one:

```bash
\cp -f ~/.dotfiles/config/karabiner/karabiner.json ~/.config/karabiner/karabiner.json
```


## Features

- Right command -> F18  (map F18 to switching the input source: System Settings > Keyboard > Keyboard Shortcuts > Input Sources)
