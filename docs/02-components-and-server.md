# Список компонентов и настройка серверной части

← [01-overview](01-overview.md) | [Оглавление](smart-greenhouse-design.md) | [03-greenhouse-installation](03-greenhouse-installation.md) →

---

> Цены ориентировочные для РФ, весна–лето 2025–2026 гг. (Ozon, Яндекс Маркет, iArduino, Чип и Дип, профильные магазины). Перед заказом проверяйте актуальную стоимость и наличие.

Сеть Wi‑Fi/Mesh и VLAN — в [§3](01-overview.md#3-настройка-wi-fi-и-mesh). Щит, датчики в теплице и гидравлика — [03](03-greenhouse-installation.md), [04](04-esp32-and-cabinet.md).

## 1. Подбор компонентов
### 1.1. Серверная часть (дом, сетевой шкаф)

![Raspberry Pi 5 — одноплатный компьютер для Home Assistant](images/components/raspberry-pi-5.jpg)

*Рекомендуемая связка ★: Raspberry Pi 5 4 ГБ + Waveshare PoE M.2 HAT+ + NVMe 128 ГБ.*

| Узел | Бюджет | Сбалансированный ★ | Премиум | Поиск / ссылка |
|------|--------|-------------------|---------|----------------|
| Плата HA | Raspberry Pi 4 Model B 4 ГБ | **Raspberry Pi 5 4 ГБ** | Raspberry Pi 5 8 ГБ | `Raspberry Pi 5 4GB купить` — [iArduino](https://www.iarduino.ru/shop/boards/raspberry-pi-5-4gb.html), [robotclass.ru](https://shop.robotclass.ru/) |
| PoE | PoE HAT для Pi 4 (802.3af) | **Waveshare PoE M.2 HAT+ для Pi 5** (802.3at) | Официальный Raspberry Pi PoE+ HAT | `Waveshare PoE M.2 HAT+ Pi 5` |

![Waveshare PoE M.2 HAT+ — питание Raspberry Pi 5 по Ethernet и слот NVMe 2230](images/components/waveshare-poe-m2-hat-plus.jpg)
| Накопитель | USB SSD 128 ГБ (Kingston SA400) + переходник USB 3.0 | **NVMe 128 ГБ 2230** (Kingston NV2 / WD SN580) в M.2 HAT | NVMe 256 ГБ + резервная копия на USB | `NVMe 2230 128GB`, `SSD USB 3.0 128GB` |
| Охлаждение | Пассивный радиатор Pi 4 | **Active Cooler Pi 5** + корпус с вентиляцией шкафа | Корпус Argon NEO 5 + температурный монитор | `Raspberry Pi 5 Active Cooler` |
| ОС | Home Assistant OS (официальный образ) | Home Assistant OS | HA OS + add-on InfluxDB/Grafana | [home-assistant.io/installation](https://www.home-assistant.io/installation/) |
| Альтернатива Pi | Orange Pi 5 / x86 NUC б/у | — | Home Assistant Green (готовое устройство) | `Home Assistant Green купить` |

**Рекомендация ★:** Raspberry Pi 5 4 ГБ + Waveshare PoE M.2 HAT+ + NVMe 128 ГБ. Загрузка с NVMe надёжнее microSD при постоянной записи истории HA.

| Компонент | Кол-во | Цена ★, ₽ | Сумма, ₽ |
|-----------|--------|-----------|----------|
| Raspberry Pi 5 4 ГБ | 1 | 13 000–15 000 | 14 000 |
| Waveshare PoE M.2 HAT+ | 1 | 3 500–4 500 | 4 000 |
| NVMe 128 ГБ 2230 | 1 | 2 000–2 800 | 2 400 |
| Active Cooler + корпус | 1 | 1 500–2 500 | 2 000 |
| Patch‑cord Cat6 в шкаф | 1 | 200–400 | 300 |
| **Итого сервер** | | | **~22 700** |

---

### 1.2. Сеть Mesh

![Netcraze Stellar 6 — mesh‑узел с поддержкой PoE для покрытия теплицы](images/components/netcraze-stellar-6.jpg)

*Mesh‑узел Stellar 6 (PoE 802.3af) и маршрутизатор Keenetic Speedster в сетевом шкафу; отдельный PoE‑инжектор не требуется.*

| Узел | Бюджет | Сбалансированный ★ | Премиум |
|------|--------|-------------------|---------|
| Маршрутизатор | Keenetic 4G / Start | **Keenetic Speedster (KN-3013)** | Keenetic Ultra / Giga |
| Mesh‑узел | — | **Netcraze Stellar 6** (уже в наличии) | **Netcraze Stellar 6** (уже в наличии) |
| PoE в шкафу | — | **Keenetic PoE‑коммутатор (уже есть)** — Pi HA (PoE HAT) и Stellar 6, без инжектора | Второй PoE‑коммутатор или порты PoE+ (802.3at) при росте нагрузки |

Поиск: `Keenetic Speedster KN-3013`, `Netcraze Stellar 6 mesh`

**Питание ★:** Stellar 6 поддерживает PoE (802.3af); сервер HA — через Waveshare PoE M.2 HAT+ (802.3at). Оба устройства подключаются к **уже установленному Keenetic PoE‑коммутатору** в сетевом шкафу патч‑кордами Cat6 (для AP — наружный кабель). Отдельный PoE‑инжектор не требуется.

---

### 1.6. Сводная стоимость по сценариям

| Категория | Минимальный | Сбалансированный ★ | Максимальный |
|-----------|-------------|-------------------|--------------|
| Сервер HA (Pi + PoE + SSD) | Pi 4 + USB SSD ~15 000 | Pi 5 + NVMe ~22 700 | Pi 5 8 ГБ + 256 ГБ NVMe + Grafana ~35 000 |
| Сеть (если покупать с нуля) | 0 (есть Speedster, Keenetic PoE, Stellar 6) | 0 (есть Speedster, Keenetic PoE, Stellar 6) | 0 (есть Speedster, Keenetic PoE, Stellar 6) |
| Щит, ESP32, питание | ~14 000 | ~20 000 | ~28 000 (+ ИБП, premium щит) |
| Датчики | ~2 000 | ~3 100 | ~5 500 (SHT35, ультразвук) |
| Клапаны, серво, монтаж | ~2 000 | ~2 700 | ~6 000 |
| Кабель, мелочёвка, 10% запас | ~2 000 | ~3 500 | ~5 000 |
| **ИТОГО** | **~35 000 ₽** | **~52 000 ₽** | **~74 500 ₽** |

Поисковые запросы для сверки цен на Яндекс Маркете:

```
Raspberry Pi 5 4GB
ESP32 WROOM 32U DevKit
Mean Well LRS-100-12
SHT31 датчик влажности I2C
соленоидный клапан 12V NC полив
MG996R сервопривод
PCA9685 драйвер сервоприводов
щит IP65 300x400
```

---


---

← [01-overview](01-overview.md) | [Оглавление](smart-greenhouse-design.md) | [03-greenhouse-installation](03-greenhouse-installation.md) →

---

