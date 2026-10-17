![Signed](https://img.shields.io/badge/Signed-No-FF3333)
![Trackmania2020](https://img.shields.io/badge/Game-Trackmania-blue)

# Slightly Better Checkpoint Counter

The existing checkpoint counters in this game either brakes in specific cases, are embedded in larger plugins, or do not have the features I want.
The 'Slightly Better Checkpoint Counter' plugin is therefore a way to fix these issues!

## Data source

Offset information was yoinked from the 'Unclaimed Checkpoint Indicator':

| Value | Definition |
| --- | --- |
| Arena replay record | Reflected `CSmArena.Rules` offset + `0x9F0 - 0x938` |
| Ghost checkpoint buffer | Reflected `CGameCtnGhost.NbRespawns` offset + `0x8` |
| Buffer length | Buffer field + `0x8` |
| Checkpoint entry | `nat2` (landmark index, race time), stride `0x8` |
| Landmark ID mask | `0x03000000` |

The reader selects the newest record that matches the local players login. It then matches the landmarks on themap against the IDs of the checkpoints. This means that progress comes directly from the raw buffer!

## Build

```powershell
python _build.py
```

## Author

ar

special thanks: ArEyeses and XertroV