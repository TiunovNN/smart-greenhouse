# Общее описание возможностей проекта

[Оглавление](smart-greenhouse-design.md) | [02-components-and-server](02-components-and-server.md) →

---

Документ описывает архитектуру, сеть, автоматизации, эксплуатацию и безопасность системы умной теплицы на Home Assistant. Подбор компонентов — [02-components-and-server.md](02-components-and-server.md); монтаж в теплице — [03-greenhouse-installation.md](03-greenhouse-installation.md); прошивка ESP32 и щит — [04-esp32-and-cabinet.md](04-esp32-and-cabinet.md).

Центральный сервер — Home Assistant (PoE, SSD); периферия — два контроллера ESP32 в щите IP65 у теплицы (~5 м от точки Wi‑Fi Mesh).

**Соглашения об именовании** (репозиторий `smart-greenhouse`, конфигов ESPHome/HA пока нет):

| Объект | Имя |
|--------|-----|
| ESP32 №1 | `greenhouse-watering` |
| ESP32 №2 | `greenhouse-climate` |
| Префикс сущностей HA | `greenhouse_*` |

---

## 3. Настройка Wi‑Fi и Mesh
### 3.1. Топология

```
[Интернет] → Keenetic Speedster (главный, в доме)
                 │
                 ├── 5 GHz — SSID «Home» (телефоны, ноутбуки)
                 │
                 └── 2.4 GHz — SSID «IoT-GH» (фикс. канал 6)
                          │
                          └── Netcraze Stellar 6 (Mesh, ближе к теплице)
                                    │
                                    └── ESP32 #1, ESP32 #2 (~−55…−70 dBm)
```

**Netcraze Stellar 6** (арт. **NAP-650**; в международной линейке — Keenetic Stellar 6 / KAP-650) — уличная Mesh‑точка доступа Wi‑Fi 6 (AX3000) с PoE и влагозащищённым корпусом. Питание — от **Keenetic PoE‑коммутатора** в сетевом шкафу (Cat6 наружный до точки монтажа). В связке с **Keenetic Speedster** как контроллером Mesh она расширяет сегмент `IoT-GH` на 2.4 ГГц до щита ESP32 без отдельной настройки на extender. Для теплицы: установите узел **между домом и щитом IP65**, на расстоянии **~5 м от щита** (на высоте 1.5–2 м) — так оба ESP32 остаются в зоне уверенного приёма.

### 3.2. Отдельный SSID и фиксированный канал на Keenetic Speedster

**Шаг 1. Сканирование эфира**

1. На ноутбуке: WiFi Analyzer (Windows/Android) или `keenetic` → **Диагностика → Wi‑Fi монитор**.
2. Запишите занятость каналов 1, 6, 11. Выберите **наименее загруженный** (рекомендация: **канал 6**, ширина **20 MHz**).

**Шаг 2. Создание сегмента IoT (KeeneticOS 4.x)**

1. Веб‑интерфейс `192.168.1.1` → **Мои сети и Wi‑Fi** → **Сегменты сети** → **+ Добавить сегмент**.
2. Имя сегмента: `IoT_Greenhouse`.
3. IP‑подсеть: `192.168.30.0/24` (не пересекается с домашней `192.168.1.0/24`).
4. DHCP: включить, пул `192.168.30.100–192.168.30.200`.
5. **Wi‑Fi 2.4 GHz** → новая точка доступа:
   - SSID: `IoT-GH`
   - Пароль: длинная фраза (WPA2‑PSK минимум)
   - **Канал: 6** (вручную, не «Авто»)
   - **Ширина канала: 20 MHz**
   - **802.11 b/g/n**, отключить AX на этом SSID если есть опция (ESP32 — Wi‑Fi 4)
6. **5 GHz для IoT:** не создавать — ESP32 работает только 2.4 GHz.
7. Сохранить → **Применить**.

**Шаг 3. Mesh Netcraze Stellar 6**

1. Подключить Stellar 6 к порту **PoE** на Keenetic PoE‑коммутаторе в шкафу (Cat6, для улицы — наружный кабель).
2. **Mesh‑система** → убедиться, что Stellar 6 в режиме **Mesh‑точка**, не отдельный роутер.
3. На Stellar 6 **не транслировать отдельный SSID** — только backhaul + тот же `IoT-GH` с главного Speedster (единый SSID Mesh).
4. Разместить Stellar 6 **между домом и теплицей**, на высоте 1.5–2 м, антенны вертикально.

**Шаг 4. Резервирование IP для ESP32**

1. **Сегмент IoT** → DHCP → **Зарезервировать адрес** по MAC:
   - `greenhouse-watering` → `192.168.30.11`
   - `greenhouse-climate` → `192.168.30.12`

**Шаг 5. Минимизация роуминга ESP32**

| Мера | Действие |
|------|----------|
| Один SSID Mesh | Не дублировать гостевые/домашние SSID на 2.4 GHz |
| Фиксированный канал | Канал 6 на **всех** Mesh‑узлах 2.4 GHz (Speedster + Stellar) |
| Отключить Band Steering | Для сегмента IoT — только 2.4 GHz, без принудительного 5 GHz |
| Мощность TX | На IoT‑AP: 100%; на дальних AP — не выше, чем у ближнего (избегать «пинг‑понга») |
| `fast_connect` в ESPHome | Сохранение BSSID (см. YAML) — привязка к ближайшей точке |
| Размещение | Антенны ESP32 **снаружи** металлического щита, вертикально |
| Мониторинг | RSSI в ESPHome; при `< −85 dBm` — перезагрузка Wi‑Fi (см. конфиг) |

**CLI (опционально, привязка к BSSID Stellar 6):**

После первого подключения ESP32 запомните BSSID ближайшей точки (ESPHome лог / роутер «Клиенты»). В YAML: `bssid: "AA:BB:CC:DD:EE:FF"`.

Поиск: `Keenetic сегмент сети IoT`, `Keenetic фиксированный канал 2.4`

---

### 4.5. Примеры автоматизаций Home Assistant

Добавить в `configuration.yaml` или через **Настройки → Автоматизации → Создать → Редактировать в YAML**.

**1. Полив по влажности и времени (утро)**

```yaml
alias: "Теплица — полив по влажности"
description: "Полив 5 мин если средняя влажность < 55% и светло"
mode: single
trigger:
  - platform: time
    at: "07:00:00"
condition:
  - condition: numeric_state
    entity_id: sensor.teplitsa_srednyaya_vlazhnost
    below: 55
  - condition: numeric_state
    entity_id: sensor.osveshchennost_potolok
    above: 500
action:
  - service: switch.turn_on
    target:
      entity_id: switch.greenhouse_watering_klapan_poliva
  - delay: "00:05:00"
  - service: switch.turn_off
    target:
      entity_id: switch.greenhouse_watering_klapan_poliva
```

**2. Наполнение бака по уровню**

```yaml
alias: "Теплица — наполнение бака"
mode: single
trigger:
  - platform: state
    entity_id: binary_sensor.greenhouse_watering_bak_vysokiy_uroven
    from: "on"
    to: "off"
    for: "00:01:00"
condition:
  - condition: state
    entity_id: binary_sensor.greenhouse_watering_bak_vysokiy_uroven
    state: "off"
action:
  - service: switch.turn_on
    target:
      entity_id: switch.greenhouse_watering_klapan_napolneniya_baka
  - wait_for_trigger:
      - platform: state
        entity_id: binary_sensor.greenhouse_watering_bak_vysokiy_uroven
        to: "on"
    timeout: "00:10:00"
  - service: switch.turn_off
    target:
      entity_id: switch.greenhouse_watering_klapan_napolneniya_baka
```

**3. Защита от переполнения (аварийное отключение)**

```yaml
alias: "Теплица — защита переполнения бака"
mode: restart
trigger:
  - platform: state
    entity_id: binary_sensor.greenhouse_watering_bak_vysokiy_uroven
    to: "on"
    for: "00:00:05"
action:
  - service: switch.turn_off
    target:
      entity_id: switch.greenhouse_watering_klapan_napolneniya_baka
  - service: notify.persistent_notification
    data:
      title: "Теплица — переполнение бака"
      message: "Клапан наполнения принудительно закрыт."
```

**4. Проветривание по температуре и влажности (триангуляция)**

Стратегия: **max T** по трём зонам SHT31 — перегрев в любой точке открывает форточки; **средняя RH** — риск конденсата. Полное открытие при max T > 32 °C.

```yaml
alias: "Теплица — проветривание"
description: "max T > 28 °C или средняя RH > 85%; полное открытие при max T > 32 °C"
mode: single
trigger:
  - platform: numeric_state
    entity_id: sensor.teplitsa_max_temperatura
    above: 28
    for: "00:05:00"
  - platform: numeric_state
    entity_id: sensor.teplitsa_srednyaya_vlazhnost
    above: 85
    for: "00:10:00"
condition:
  - condition: or
    conditions:
      - condition: numeric_state
        entity_id: sensor.teplitsa_max_temperatura
        above: 28
      - condition: numeric_state
        entity_id: sensor.teplitsa_srednyaya_vlazhnost
        above: 85
action:
  - choose:
      - conditions:
          - condition: numeric_state
            entity_id: sensor.teplitsa_max_temperatura
            above: 32
        sequence:
          - service: cover.set_cover_position
            target:
              entity_id: cover.fortochka_1
            data:
              position: 100
          - service: cover.set_cover_position
            target:
              entity_id: cover.fortochka_2
            data:
              position: 100
    default:
      - service: cover.set_cover_position
        target:
          entity_id:
            - cover.fortochka_1
            - cover.fortochka_2
        data:
          position: 40
```

**5. Закрытие окон на ночь и при дожде (низкая освещённость + высокая влажность)**

```yaml
alias: "Теплица — закрыть форточки на ночь"
mode: single
trigger:
  - platform: sun
    event: sunset
    offset: "00:30:00"
  - platform: numeric_state
    entity_id: sensor.osveshchennost_potolok
    below: 10
    for: "00:15:00"
action:
  - service: cover.close_cover
    target:
      entity_id:
        - cover.fortochka_1
        - cover.fortochka_2
```

---

## 5. Диагностика и обслуживание
### 5.1. Чек‑лист после сборки

| № | Проверка | Ожидание | ✓ |
|---|----------|----------|---|
| 1 | Напряжение 5 V под нагрузкой | 4.95–5.10 V | |
| 2 | Напряжение 12 V | 11.8–12.2 V | |
| 3 | ESP32 #1/#2 в сети, ping | Ответ < 5 ms в LAN | |
| 4 | RSSI обоих ESP32 | > −75 dBm (цель), не ниже −85 | |
| 5 | Клапаны без питания | Закрыты (NC), нет течи | |
| 6 | Реле OFF → клапан | Закрыт | |
| 7 | Реле ON 2 с → клапан | Открыт, нет просадки 12 V > 0.5 V | |
| 8 | DS18B20 | Температура ±0.5 °C от эталона | |
| 9 | SHT31 (3 шт.) | Разброс < 1 °C / 3 % RH | |
| 10 | Поплавок | Срабатывание на полном баке | |
| 11 | YF‑S201 | Импульсы при ручном проливе | |
| 12 | Серво | 0° закрыто, 90° открыто, без дребезга | |
| 13 | OTA ESPHome | Обновление без USB | |
| 14 | HA история | Графики 24 ч без пропусков | |
| 15 | Автоматизации | Тест в «Режиме трассировки» | |
| 16 | Gore vent / сальники | Нет конденсата внутри щита | |

### 5.2. Типичные проблемы и решения

| Симптом | Вероятная причина | Решение |
|---------|-------------------|---------|
| ESP32 offline, RSSI < −90 | Слабый сигнал, металл щита | Вынести антенну, сдвинуть Stellar 6, зафиксировать BSSID |
| Частые reconnect | Роуминг Mesh, канал Auto | Фикс. канал 6, 20 MHz, `power_save_mode: none` |
| Ложное «переполнение бака» | Дребезг поплавка | Конденсатор 100 nF, `for:` 5–10 с в автоматизации |
| Расход 0 при поливе | Неправильная калибровка YF‑S201 | Подстроить `multiply`; проверить 5 V на датчике |
| SHT31 «nan» | Длина I2C > 3 m без pull-up | Pull-up 4.7 kΩ на SDA/SCL, FTP, снизить частоту I2C |
| Серво дёргается | Питание 5 V с ESP32 | Отдельный БП 5 V 3 A на V+ PCA9685 |
| Просадка 12 V при клапане | БП слабый / тонкие провода | LRS‑100‑12, сечение ≥ 1.5 mm², диод 1N4007 |
| Клапан не закрывается при сбое | Relay active‑low / NO вместо NC | Проверить тип реле; только NC‑клапаны |
| HA не видит сущности | API encryption mismatch | Переподключить интеграцию ESPHome, ключ из YAML |
| Корrosion в щите | Конденсат | Gore vent, силика‑гель, обогрев зимой опционально |

### 5.3. Резервное копирование и мониторинг

**Резервное копирование HA:**

1. **Настройки → Система → Резервные копии** → ежедневно 03:00, хранить 7 локально.
2. Автокопия на NAS / Nextcloud (Samba add-on или `ha backup upload`).
3. Экспорт YAML: `esphome/` конфиги, `automations.yaml`, `configuration.yaml` — в git‑репозиторий `smart-greenhouse`.
4. Документировать пароли в менеджере (не в git).

**Мониторинг:**

| Инструмент | Назначение |
|------------|------------|
| HA **System Monitor** | CPU/RAM/диск Pi |
| **ESPHome** RSSI sensors | Тренд Wi‑Fi |
| **Uptime Kuma** (add-on) | Ping ESP32, HA UI |
| **Alert** при offline > 5 min | notify Telegram/mobile |
| **Recorder** | `purge_keep_days: 30`, исключить частые pulse |
| Опционально **InfluxDB + Grafana** | Долгая история T/H, расход воды |

**Регламент обслуживания:**

- Еженедельно: просмотр графиков, тест ручного полива/форточки.
- Ежемесячно: очистка фильтра линии воды, осмотр сальников.
- Ежеквартально: OTA ESPHome + обновление HA (с бэкапом), калибровка расходомеров.
- Ежегодно: замена силика‑геля, проверка клапанов под давлением.

---

## 6. Безопасность
### 6.1. Сегментация сети (VLAN / IoT)

```
[Интернет]
    │
[Keenetic Speedster]
    ├── VLAN/Home  192.168.1.0/24  — ПК, телефоны (доверенные)
    ├── VLAN/IoT   192.168.30.0/24 — ESP32, камеры (ограниченные)
    └── VLAN/Mgmt  192.168.99.0/24 — коммутатор, AP (опц.)

Firewall (IoT → Home): DENY по умолчанию
Firewall (Home → IoT): ALLOW только HA (192.168.1.x → ESP32:6053 API)
Firewall (IoT → Internet): DENY (ESP32 не нужен выход в интернет после OTA)
```

**Keenetic — правила межсегментного экрана:**

1. **Правила и политики → Межсетевой экран → IoT_Greenhouse**.
2. Запретить: `IoT → Любой → Домашняя сеть` (192.168.1.0/24).
3. Разрешить: `Домашняя → IoT → TCP 6053` (ESPHome native API, если используется).
4. Запретить: `IoT → Интернет` (или разрешить только NTP при необходимости).

### 6.2. Доступ к ESP32

| Мера | Реализация |
|------|------------|
| Нет прямого интернета | Firewall deny IoT WAN |
| OTA | Только из LAN через HA ESPHome add-on |
| API encryption | `api.encryption.key` в YAML |
| OTA password | Обязательно |
| Fallback AP | Отключать после стабилизации (`ap_timeout: 0` или без AP в prod) |
| mDNS | Доступ к `greenhouse-watering.local` только из LAN |

### 6.3. Обновление прошивок

1. **ESPHome:** подписаться на [ESPHome releases](https://github.com/esphome/esphome/releases); обновлять add-on → Compile → OTA (по одному устройству).
2. **Home Assistant:** Core/OS — раз в месяц после бэкапа; читать release notes.
3. **Keenetic:** KeeneticOS stable channel; не включать beta на production.
4. Откат ESPHome: хранить предыдущий `.bin` из ESPHome dashboard.

### 6.4. Физическая безопасность

- Автомат 10 A и УЗО на линии 220 V в щите теплицы.
- Заземление корпуса металлического щита.
- Клапаны NC — **fail‑safe** при обесточивании.
- ИБП 12 V только для удержания клапанов в безопасном состоянии (закрыты).

### 6.5. Чек‑лист безопасности

- [ ] IoT в отдельной подсети / VLAN
- [ ] ESP32 без доступа в интернет
- [ ] Уникальные пароли Wi‑Fi / OTA / API
- [ ] Резервные копии HA зашифрованы
- [ ] SSH/Port forwarding на HA не открыт в интернет без VPN
- [ ] Доступ к HA UI через HTTPS (Nginx Proxy / Cloudflare Tunnel + 2FA)

---

## Приложение A. Структура репозитория (рекомендуемая)

```
smart-greenhouse/
├── docs/
│   ├── smart-greenhouse-design.md    ← оглавление
│   ├── 01-overview.md
│   ├── 02-components-and-server.md
│   ├── 03-greenhouse-installation.md
│   └── 04-esp32-and-cabinet.md
├── esphome/
│   ├── greenhouse-watering.yaml
│   ├── greenhouse-climate.yaml
│   └── secrets.yaml                ← в .gitignore
├── homeassistant/
│   └── automations/
│       └── greenhouse.yaml
├── Task.md
└── README.md
```

## Приложение B. Полезные ссылки

- [ESPHome — Pulse Counter](https://esphome.io/components/sensor/pulse_counter.html)
- [ESPHome — PCA9685](https://esphome.io/components/output/pca9685.html)
- [Keenetic — Сегменты сети](https://support.keenetic.com/hero-4g-plus/kn-2311/en/14628-network-segments.html)
- [Keenetic Speedster — Wi‑Fi 2.4 GHz](https://support.keenetic.ua/speedster/kn-3013/uk/14630-2-4-ghz-wi-fi-network.html)
- [Home Assistant — Backup](https://www.home-assistant.io/common-tasks/general/#backups)

---

*Документ подготовлен для проекта smart-greenhouse. Перед монтажом сверьте GPIO, I2C‑адреса и калибровку расходомеров на стенде.*

---

[Оглавление](smart-greenhouse-design.md) | [02-components-and-server](02-components-and-server.md) →

---

