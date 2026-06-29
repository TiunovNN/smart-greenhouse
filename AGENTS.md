# AGENTS.md — Smart Greenhouse

Guide for AI agents and contributors working on this repository.

## Project purpose

Smart greenhouse automation built on **Home Assistant** (logic, automations, dashboard) and **ESPHome** (two ESP32 nodes: watering/tank and climate/windows). Controllers live in an **IP65 cabinet mounted outside at the greenhouse entrance** (not inside the humid interior) **during the growing season (~May–September, central Russia)**; **in winter the cabinet is powered off, removed from its mount, and stored dry indoors** ([docs/03-greenhouse-installation.md §0.1](docs/03-greenhouse-installation.md#01-сезонная-эксплуатация-монтаж-и-демонтаж-щита)). Sensors, actuators, and optional PoE cameras remain **inside** the greenhouse (typical RH **70–95%**). ESP32/edge automations are inactive while the cabinet is stored; HA may show unavailable entities. The full hardware design, wiring, and rationale are in [docs/smart-greenhouse-design.md](docs/smart-greenhouse-design.md) (index, Russian) and five linked docs: [01-overview](docs/01-overview.md), [02-components-and-server](docs/02-components-and-server.md), [03-greenhouse-installation](docs/03-greenhouse-installation.md), [04-esp32-and-cabinet](docs/04-esp32-and-cabinet.md), [05-computer-vision](docs/05-computer-vision.md) (optional CV design — not in base BOM).

## Repository layout

```
smart-greenhouse/
├── docs/
│   ├── smart-greenhouse-design.md   # Index (source of truth entry point)
│   ├── 01-overview.md               # Architecture, network, automations, ops, security
│   ├── 02-components-and-server.md  # BOM, HA server, Mesh hardware
│   ├── 03-greenhouse-installation.md # Sensors, actuators, hydraulic layout
│   ├── 04-esp32-and-cabinet.md      # Cabinet, GPIO, ESPHome, entity IDs
│   └── 05-computer-vision.md        # Optional: cameras, cloud CV (design only)
├── esphome/
│   ├── greenhouse-watering.yaml     # ESP32 #1 — irrigation, tank, flow meters
│   ├── greenhouse-climate.yaml      # ESP32 #2 — climate sensors, vent windows
│   ├── secrets.yaml.example         # Template for credentials (copy to secrets.yaml)
│   └── secrets.yaml                 # Local credentials — NEVER commit
├── homeassistant/
│   ├── automations/
│   │   ├── greenhouse.yaml          # HA automations referencing ESPHome entities
│   │   └── greenhouse_cv.yaml.example  # Optional CV capture/analyze (not active by default)
│   ├── input_select.yaml            # Plant profile selector (include in configuration.yaml)
│   ├── input_number.yaml            # Setpoints — irrigation, vent thresholds (include in configuration.yaml)
│   ├── input_button.yaml            # Soil probe calibration wizard buttons
│   ├── scripts/greenhouse_soil_cal.yaml  # Guided dry/wet soil calibration script
│   ├── input_boolean.yaml           # Season gate greenhouse_season_active
│   └── plant_profiles.yaml          # Profile default values (reference; applied by automation)
├── .cursor/
│   └── skills/
│       ├── esphome/                 # ESPHome firmware skill (from aurora-smart-home, adapted)
│       └── home-assistant/          # HA YAML skill (from aurora-smart-home, adapted)
├── AGENTS.md                        # This file
├── Task.md                          # Task tracking
└── README.md                        # Quick start for humans
```

## Naming conventions

| Item | Convention | Example |
|------|------------|---------|
| ESPHome device name | kebab-case | `greenhouse-watering`, `greenhouse-climate` |
| ESPHome internal IDs | snake_case | `valve_irrigation`, `temp_center_top`, `temp_entrance_low` |
| HA entity prefix | Derived from device name | `greenhouse_watering_*`, climate entities from Russian friendly names |
| Automation IDs | snake_case, prefixed | `greenhouse_irrigation_by_soil_moisture` |
| Plant profile select | `input_select.greenhouse_plant_profile` | States: `Огурцы`, `Помидоры` |
| Profile setpoints | `input_number.greenhouse_*` | See `plant_profiles.yaml` and `docs/01-overview.md` §4.6 (central Russia defaults + seasonal notes) |

Home Assistant generates `entity_id` values from friendly names (often transliterated Russian). After first pairing, verify entity IDs in **Settings → Devices** and update `homeassistant/automations/greenhouse.yaml` if they differ from the design doc examples.

## Editing ESPHome configs

### Secrets

1. Copy `esphome/secrets.yaml.example` → `esphome/secrets.yaml`.
2. Fill Wi-Fi, OTA, AP, and API encryption key.
3. Generate API key: `esphome secrets generate-key` or via ESPHome dashboard.
4. Never commit `secrets.yaml`.

### GPIO and calibration

- Pin assignments are fixed in the design doc ([04-esp32-and-cabinet.md](docs/04-esp32-and-cabinet.md) §4.2 / §4.3). Change only when hardware changes.
- **Flow meters** (`multiply: 0.00222`): calibrate against known volume; design doc notes ~450 pulses/L for YF-S201.
- **DS18B20 address** (`0x000000000000` in watering config): replace after first OneWire scan.
- **Wi-Fi BSSID** (watering config): uncomment and set after identifying the nearest mesh AP.
- **Servo PWM** (`min_power` / `max_power`): tune for MG996R travel on each window.

### Flash and deploy

```bash
cd esphome
cp secrets.yaml.example secrets.yaml   # edit first
esphome run greenhouse-watering.yaml   # first flash via USB
esphome run greenhouse-climate.yaml
# Subsequent updates: esphome run ... or OTA from ESPHome dashboard
```

Static IPs: watering `192.168.30.11`, climate `192.168.30.12`, optional CV edge SBC `192.168.30.13` on IoT VLAN (see [01-overview.md](docs/01-overview.md) §3, [02 §1.7](docs/02-components-and-server.md)).

## Home Assistant automations

Automations in `homeassistant/automations/greenhouse.yaml` orchestrate ESPHome entities:

| Automation | Triggers | ESPHome entities used |
|------------|----------|------------------------|
| Применить профиль культуры | Profile change / HA start | `input_select`, `input_number` helpers |
| Полив по влажности почвы | 07:00 daily | min soil moisture (6 probes), lux, irrigation valve |
| Наполнение бака | Tank level drops | fill valve, level sensor |
| Защита переполнения | Level high 5 s | fill valve off + notification |
| Проветривание | max T or avg RH above profile setpoints | triangulation sensors, vent covers |
| Закрыть форточки на ночь | Sunset + low lux | vent covers |

**Seasonal:** cabinet removed ~Oct–Apr; ESP32 offline → set `input_boolean.greenhouse_season_active` to **off** so greenhouse automations skip actuators; entities may show unavailable ([03 §0.1](docs/03-greenhouse-installation.md#01-сезонная-эксплуатация-монтаж-и-демонтаж-щита), [01 §5.4](docs/01-overview.md#54-сезонная-эксплуатация)). Helper in `homeassistant/input_boolean.yaml`.

Optional computer vision (design in [05-computer-vision.md](docs/05-computer-vision.md)): 2× PoE IP cameras for **П‑layout** beds **inside** the greenhouse; **Radxa ZERO 3W edge SBC** (`192.168.30.13`) in the **outdoor IP65 cabinet** — **local-only** RTSP capture, optional ONNX pre-filter, delivers images to Pi via LAN (SCP/HTTP/MQTT); **Raspberry Pi 5 / HA** uploads to **Yandex Object Storage** and calls **Yandex AI Studio** (Foundation Models); snapshots **07:00 + sunset−45m** gated by BH1750 lux; vent/irrigation coupling on Pi — see `greenhouse_cv.yaml.example` and `scripts/capture_and_analyze.sh` (Pi-side). Edge reference: `edge_capture.sh` (not in repo).

Profile helpers (`input_select.greenhouse_plant_profile`, `input_number.greenhouse_*`): include `input_select.yaml` and `input_number.yaml` in `configuration.yaml`. Defaults target **central Russia** (peak season); seasonal manual tweaks — `plant_profiles.yaml` `seasonal_notes` and `docs/01-overview.md` §4.6. Greenhouse interior RH is typically **70–95%**; `vent_humidity_max` triggers vent at the **upper** band, not because 70% is “low”. Irrigation uses **minimum soil moisture** from **6 sealed capacitive probes** on `greenhouse-watering` (ADS1115 ×2, compare to `input_number.greenhouse_soil_moisture_min`). **Soil calibration:** per-probe dry/wet V via `input_select.greenhouse_soil_cal_probe` + `input_button.greenhouse_soil_cal_*` → `script.greenhouse_soil_moisture_calibrate` (see `homeassistant/scripts/greenhouse_soil_cal.yaml`, docs/03 §1.4.3).

Import via **Settings → Automations → Import** or include in `configuration.yaml`:

```yaml
automation: !include_dir_merge_list automations/
```

Entity IDs in automations must match your HA instance after ESPHome pairing. The design doc table ([04-esp32-and-cabinet.md](docs/04-esp32-and-cabinet.md) §4.4) lists expected IDs.

Use **modern HA syntax** (2024.8+): plural `triggers:` / `conditions:` / `actions:`, service calls as `action:` (not `service:`), `trigger: state` inside trigger lists (not `platform:`). See `.cursor/skills/home-assistant/SKILL.md` when editing automations.

## Cursor skills

| Skill | Path | Use when |
|-------|------|----------|
| ESPHome firmware | `.cursor/skills/esphome/` | Writing or reviewing `esphome/` device firmware, GPIO, sensors, actuators, and calibration |
| Home Assistant YAML | `.cursor/skills/home-assistant/` | Writing or reviewing `homeassistant/` automations, helpers, templates |

Adapted from [aurora-smart-home/esphome](https://github.com/tonylofgren/aurora-smart-home/tree/main/esphome) and [aurora-smart-home/home-assistant](https://github.com/tonylofgren/aurora-smart-home/tree/main/home-assistant).

## Language

- **Code, comments in repo configs, logs, AGENTS.md, README**: English (except user-facing entity friendly names in ESPHome, which match the Russian design doc).
- **Design document**: Russian — authoritative for hardware and network decisions.

## Security

- Do not commit real secrets, API keys, Wi-Fi passwords, or OTA passwords.
- `esphome/secrets.yaml` and `homeassistant/secrets.yaml` are gitignored.
- Use the IoT VLAN and API encryption as specified in the design doc.

## When making changes

1. Read [docs/smart-greenhouse-design.md](docs/smart-greenhouse-design.md) (index) and the relevant split doc for context.
2. Keep ESPHome YAML aligned with [04-esp32-and-cabinet.md](docs/04-esp32-and-cabinet.md) §4.2 and §4.3 unless hardware changed.
3. Update HA automations when entity IDs or logic change.
4. Wrap prose in all Markdown files to a maximum line length of 100 characters; Markdown tables are exempt.
5. Test on device or with `esphome config <file>.yaml` before suggesting deploy.
