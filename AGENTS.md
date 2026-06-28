# AGENTS.md — Smart Greenhouse

Guide for AI agents and contributors working on this repository.

## Project purpose

Smart greenhouse automation built on **Home Assistant** (logic, automations, dashboard) and **ESPHome** (two ESP32 nodes: watering/tank and climate/windows). The full hardware design, wiring, and rationale are in [docs/smart-greenhouse-design.md](docs/smart-greenhouse-design.md) (Russian).

## Repository layout

```
smart-greenhouse/
├── docs/
│   └── smart-greenhouse-design.md   # Source of truth (hardware, network, YAML specs)
├── esphome/
│   ├── greenhouse-watering.yaml     # ESP32 #1 — irrigation, tank, flow meters
│   ├── greenhouse-climate.yaml      # ESP32 #2 — climate sensors, vent windows
│   ├── secrets.yaml.example         # Template for credentials (copy to secrets.yaml)
│   └── secrets.yaml                 # Local credentials — NEVER commit
├── homeassistant/
│   ├── automations/
│   │   └── greenhouse.yaml          # HA automations referencing ESPHome entities
│   └── input_number.yaml            # Dashboard helpers (include in configuration.yaml)
├── .cursor/
│   └── skills/
│       └── home-assistant/          # HA YAML skill (from aurora-smart-home, adapted)
├── AGENTS.md                        # This file
├── Task.md                          # Task tracking
└── README.md                        # Quick start for humans
```

## Naming conventions

| Item | Convention | Example |
|------|------------|---------|
| ESPHome device name | kebab-case | `greenhouse-watering`, `greenhouse-climate` |
| ESPHome internal IDs | snake_case | `valve_irrigation`, `temp_center` |
| HA entity prefix | Derived from device name | `greenhouse_watering_*`, climate entities from Russian friendly names |
| Automation IDs | snake_case, prefixed | `greenhouse_irrigation_by_humidity` |

Home Assistant generates `entity_id` values from friendly names (often transliterated Russian). After first pairing, verify entity IDs in **Settings → Devices** and update `homeassistant/automations/greenhouse.yaml` if they differ from the design doc examples.

## Editing ESPHome configs

### Secrets

1. Copy `esphome/secrets.yaml.example` → `esphome/secrets.yaml`.
2. Fill Wi-Fi, OTA, AP, and API encryption key.
3. Generate API key: `esphome secrets generate-key` or via ESPHome dashboard.
4. Never commit `secrets.yaml`.

### GPIO and calibration

- Pin assignments are fixed in the design doc (section 4.2 / 4.3). Change only when hardware changes.
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

Static IPs: watering `192.168.30.11`, climate `192.168.30.12` on IoT VLAN (see design doc section 3).

## Home Assistant automations

Automations in `homeassistant/automations/greenhouse.yaml` orchestrate ESPHome entities:

| Automation | Triggers | ESPHome entities used |
|------------|----------|------------------------|
| Полив по влажности | 07:00 daily | humidity, lux, irrigation valve |
| Наполнение бака | Tank level drops | fill valve, level sensor |
| Защита переполнения | Level high 5 s | fill valve off + notification |
| Проветривание | Temp > 28 °C or humidity > 85% | center temp, avg humidity, vent covers |
| Закрыть форточки на ночь | Sunset + low lux | vent covers |

Import via **Settings → Automations → Import** or include in `configuration.yaml`:

```yaml
automation: !include_dir_merge_list automations/
```

Entity IDs in automations must match your HA instance after ESPHome pairing. The design doc table (section 4.4) lists expected IDs.

Use **modern HA syntax** (2024.8+): plural `triggers:` / `conditions:` / `actions:`, service calls as `action:` (not `service:`), `trigger: state` inside trigger lists (not `platform:`). See `.cursor/skills/home-assistant/SKILL.md` when editing automations.

## Cursor skills

| Skill | Path | Use when |
|-------|------|----------|
| Home Assistant YAML | `.cursor/skills/home-assistant/` | Writing or reviewing `homeassistant/` automations, helpers, templates |

Adapted from [aurora-smart-home/home-assistant](https://github.com/tonylofgren/aurora-smart-home/tree/main/home-assistant).

## Language

- **Code, comments in repo configs, logs, AGENTS.md, README**: English (except user-facing entity friendly names in ESPHome, which match the Russian design doc).
- **Design document**: Russian — authoritative for hardware and network decisions.

## Security

- Do not commit real secrets, API keys, Wi-Fi passwords, or OTA passwords.
- `esphome/secrets.yaml` and `homeassistant/secrets.yaml` are gitignored.
- Use the IoT VLAN and API encryption as specified in the design doc.

## When making changes

1. Read [docs/smart-greenhouse-design.md](docs/smart-greenhouse-design.md) for context.
2. Keep ESPHome YAML aligned with sections 4.2 and 4.3 unless hardware changed.
3. Update HA automations when entity IDs or logic change.
4. Test on device or with `esphome config <file>.yaml` before suggesting deploy.
