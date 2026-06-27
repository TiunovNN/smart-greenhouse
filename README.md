# Smart Greenhouse

Automated greenhouse control with **Home Assistant** and two **ESPHome** ESP32 nodes: irrigation/tank management and climate/ventilation.

Full hardware design, wiring, and network layout: [docs/smart-greenhouse-design.md](docs/smart-greenhouse-design.md).

Contributor and agent guide: [AGENTS.md](AGENTS.md).

## Quick start

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

### 3. Import automations

Copy or include `homeassistant/automations/greenhouse.yaml` in your HA config, e.g.:

```yaml
automation: !include_dir_merge_list automations/
```

Verify entity IDs in **Settings → Devices** match the automation file (they depend on friendly names). Adjust automations if needed.

## Repository structure

| Path | Purpose |
|------|---------|
| `esphome/greenhouse-watering.yaml` | Valves, flow meters, tank level, DS18B20 |
| `esphome/greenhouse-climate.yaml` | SHT3x, BH1750, PCA9685 servos, vent covers |
| `homeassistant/automations/greenhouse.yaml` | Irrigation, tank fill, ventilation automations |
| `docs/smart-greenhouse-design.md` | Complete system design (source of truth) |

## License

See [LICENSE](LICENSE).
