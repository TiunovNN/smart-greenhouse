# Smart Greenhouse

Automated greenhouse control with **Home Assistant** and two **ESPHome** ESP32 nodes: irrigation/tank management and climate/ventilation.

Full hardware design, wiring, and network layout: [docs/smart-greenhouse-design.md](docs/smart-greenhouse-design.md) (index → [01](docs/01-overview.md) · [02](docs/02-components-and-server.md) · [03](docs/03-greenhouse-installation.md) · [04](docs/04-esp32-and-cabinet.md) · [05](docs/05-computer-vision.md)).

Contributor and agent guide: [AGENTS.md](AGENTS.md).

## Quick start

## Validation

The repository has lightweight checks for YAML shape, ESPHome compilation, profile drift, and accidental secrets:

```bash
cd tools/validation
uv run validate_greenhouse_config.py
cd ../..
yamllint .
cd esphome
esphome config greenhouse-watering.yaml
esphome config greenhouse-climate.yaml
```

GitHub Actions runs the same checks on pushes and pull requests. CI uses `ibiqlik/action-yamllint`, the official ESPHome container image, and `gitleaks/gitleaks-action`. The ESPHome job copies `secrets.yaml.example`, which contains dummy credentials, so real secrets are never needed.

### 1. ESPHome secrets

```bash
cd esphome
cp secrets.yaml.example secrets.yaml
# Edit secrets.yaml: Wi-Fi, OTA, AP password, API encryption key
# Generate API key: esphome secrets generate-key
```

### 2. Flash ESP32 nodes

First flash over USB; later updates via OTA.

```bash
esphome run greenhouse-watering.yaml   # ESP32 #1 — 192.168.30.11
esphome run greenhouse-climate.yaml    # ESP32 #2 — 192.168.30.12
```

After flashing, pair devices in Home Assistant (**ESPHome** integration → enter API encryption key).

### 3. Home Assistant helpers and automations

Include helpers and automations in `configuration.yaml`:

```yaml
input_boolean: !include input_boolean.yaml   # greenhouse_season_active — on May–Sep
input_select: !include input_select.yaml       # plant profile (Огурцы / Помидоры)
input_number: !include input_number.yaml       # irrigation / vent setpoints
input_button: !include input_button.yaml       # soil probe calibration wizard buttons
script: !include_dir_merge_named scripts/      # greenhouse_soil_moisture_calibrate
automation: !include_dir_merge_list automations/
```

Turn **`input_boolean.greenhouse_season_active`** **on** when the outdoor cabinet is mounted (~May); **off** in winter when ESP32 is stored.

Copy or include `homeassistant/automations/greenhouse.yaml`. Verify entity IDs in **Settings → Devices** match your instance.

**Optional CV** (not in base BOM): see [docs/05-computer-vision.md](docs/05-computer-vision.md). Radxa edge captures locally; Pi runs `scripts/capture_and_analyze.sh` for Yandex upload/analyze. Example automations: `homeassistant/automations/greenhouse_cv.yaml.example`.

### 4. Utility scripts

Python scripts use `uv` with the pinned version from `.python-version`:

```bash
uv python install
cd tools/bom
uv run generate_bom.py
```

## Repository structure

| Path | Purpose |
|------|---------|
| `esphome/greenhouse-watering.yaml` | Valves, flow meters, tank level, DS18B20, soil moisture (ADS1115 ×2) |
| `esphome/greenhouse-climate.yaml` | SHT3x, BH1750, current PCA9685/MG996R vent cover implementation |
| `homeassistant/input_boolean.yaml` | Season gate `greenhouse_season_active` |
| `homeassistant/input_select.yaml` | Plant profile selector |
| `homeassistant/input_number.yaml` | Profile setpoints (irrigation, vent) |
| `homeassistant/input_button.yaml` | Soil probe calibration wizard buttons |
| `homeassistant/scripts/greenhouse_soil_cal.yaml` | Guided dry/wet soil moisture calibration |
| `homeassistant/plant_profiles.yaml` | Default profile values (reference) |
| `homeassistant/automations/greenhouse.yaml` | Irrigation, tank fill, ventilation automations |
| `homeassistant/automations/greenhouse_cv.yaml.example` | Optional CV orchestration on Pi (not active by default) |
| `scripts/capture_and_analyze.sh` | Pi-side Yandex Object Storage + AI Studio stub |
| `tools/bom/generate_bom.py` | Generate `docs/smart-greenhouse-bom.*` from the curated BOM table |
| `tools/validation/validate_greenhouse_config.py` | Cross-file checks for profile drift, HA syntax, and tracked secrets |
| `docs/05-computer-vision.md` | Optional cameras, edge SBC, Pi cloud CV design |
| `docs/smart-greenhouse-design.md` | Design doc index |

## License

See [LICENSE](LICENSE).
