# Программирование ESP32 и сборка щита

← [03-greenhouse-installation](03-greenhouse-installation.md) | [Оглавление](smart-greenhouse-design.md)

---

Сборка щита IP65 **снаружи у входа**, GPIO, ESPHome и интеграция с Home Assistant. BOM щита — [§1.3](04-esp32-and-cabinet.md#13-щит-ip65-снаружи-у-входа--контроллеры-и-питание) ниже; размещение датчиков в теплице — [03 §0](03-greenhouse-installation.md#0-щит-снаружи-датчики-и-камеры-внутри); гидравлика — [§2.6](03-greenhouse-installation.md#26-гидравлическая-схема-водоснабжения-и-полива).

## 1. Подбор компонентов (щит)
### 1.3. Щит IP65 снаружи у входа — контроллеры и питание

Щит **не** размещается внутри теплицы (RH 70–95 %). Монтаж: **снаружи у входной двери**, на стенке/стойке; по возможности под **козырьком или карнизом** (защита от дождя и прямого солнца). **Сезон:** на объекте только **~май–сентябрь**; зимой **220 V отключён**, щит **снят** и хранится в сухом помещении ([03 §0.1](03-greenhouse-installation.md#01-сезонная-эксплуатация-монтаж-и-демонтаж-щита)). Внутри щита — ESP32 ×2, БП, реле, PCA9685; опционально Radxa ZERO 3W. Все полевые линии (**FTP**, силовые на клапаны/серво) уходят **в теплицу** через нижние сальники с **drip loop**.

![ESP32‑DevKit на ESP32‑WROOM‑32U с разъёмом U.FL для внешней антенны](images/components/esp32-wroom-32u.jpg)

*Щит IP65 ★: два ESP32‑WROOM‑32U, Mean Well LRS‑50‑5 / LRS‑100‑12, реле 12 В опто, PCA9685, диоды 1N4007, металлический щит DKC 300×400.*

![Щит IP65 300×400 мм — контроллеры и БП снаружи у входа в теплицу](images/components/ip65-electrical-enclosure.jpg)

![Блок питания Mean Well LRS — 5 В для логики и 12 В для реле и соленоидов](images/components/mean-well-lrs-power-supply.jpg)

![Модуль реле 12 В с оптронной развязкой — управление NC‑клапанами](images/components/relay-module-12v.jpg)

![PCA9685 — 16‑канальный PWM‑драйвер для сервоприводов форточек](images/components/pca9685-servo-driver.jpg)

| Узел | Бюджет | Сбалансированный ★ | Премиум | Поиск |
|------|--------|-------------------|---------|-------|
| ESP32 (2 шт.) | ESP32‑DevKitC на WROOM‑32 (PCB‑антенна) + внешняя антенна с переходником | **ESP32‑DevKitC на ESP32‑WROOM‑32U** (разъём U.FL/IPEX) | ESP32‑WROVER‑E 16 МБ + U.FL | `ESP32 WROOM 32U DevKit U.FL` |
| Внешняя антенна 2.4 ГГц | 2 dBi pigtail U.FL → SMA, 15 см | **5 dBi omnii, кабель 50 см**, IP65 | 8 dBi направленная на AP | `WiFi антенна 2.4GHz U.FL pigtail` |
| БП 5 В логика | Mean Well RS‑15‑5 (15 Вт) | **Mean Well LRS‑50‑5** (50 Вт, 10 А) | Дублирующий БП + ORing | `Mean Well LRS-50-5` |
| БП 12 В силовой | 12 В 3 А блок | **Mean Well LRS‑100‑12** (8.5 А) | 12 В 10 А + ИБП 12 В | `Mean Well LRS-100-12` |
| ИБП 12 В (опц.) | — | **Mini UPS 12 В 3 А** на клапаны/реле | ИБП 12 В 60 Вт | `ИБП 12V DC mini UPS` |
| Щит IP65 | Пластик 300×400×200 IP65 | **DKC R5ST0342 300×400×200** металл IP65 | 400×500×250 + клапан Gore | `щит IP65 300x400 DKC` |
| DIN‑рейка + клеммы | Клеммники винтовые | **WAGO 221‑412/413** (набор) | WAGO + маркировка | `WAGO 221 набор` |
| Сальники | PG7/PG9 пластик | **PG7/PG9 + PG11**, IP68 латунь | Многоразовые EMC‑вводы | `сальник PG9 IP68` |
| Кабель сигнальный | UTP Cat5e outdoor | **FTP Cat5e экранированный** наружный | SFTP + гофра UV | `FTP Cat5e 4 пары наружный` |
| Клапан выравнивания | — | **Gore vent IP67** на щит | — | `Gore vent IP67 электрощит` |

| Компонент | Кол-во | Цена ★, ₽ | Сумма, ₽ |
|-----------|--------|-----------|----------|
| ESP32‑WROOM‑32U DevKit | 2 | 800–1 200 | 2 000 |
| Антенна 5 dBi + pigtail | 2 | 350–600 | 900 |
| Mean Well LRS‑50‑5 | 1 | 1 800–2 400 | 2 100 |
| Mean Well LRS‑100‑12 | 1 | 2 500–3 200 | 2 850 |
| Реле 12 В опто (2‑кан.) | 2 | 250–450 | 700 |
| PCA9685 16‑канальный | 1 | 600–700 | 650 |
| Диоды 1N4007 (уже в наличии) | 4 | 0 | 0 |
| Щит DKC 300×400 IP65 | 1 | 4 500–6 500 | 5 500 |
| WAGO 221, сальники, DIN | 1 компл. | — | 2 500 |
| FTP‑кабель 50 м | 1 | 2 000–3 500 | 2 800 |
| **Итого щит (без датчиков/актуаторов)** | | | **~20 000** |

#### Антиконденсат и обслуживание (щит снаружи у влажного входа)

Щит IP65 герметичен, но **у двери теплицы** соседствует с влажным воздухом (RH 70–95 % внутри). Ночью и в прохладные месяцы (май, сентябрь) **точка росы** внутри корпуса может превысить температуру стенок → конденсат на платах и клеммах.

| Мера | Назначение | Обслуживание |
|------|------------|--------------|
| **Gore vent IP67** (верхняя/боковая стенка, не над сальниками) | Выравнивание давления, вывод влаги без прямого вливания дождя | Осмотр раз в сезон — не залит ли вент |
| **Силика‑гель** 50–100 g в контейнере на DIN‑плате | Сушка воздуха внутри при открывании двери щита | **Ежемесячно** в сезон: индикаторный гель розовеет → просушка 2 ч @ 120 °C или замена; после каждого вскрытия щита |
| **Сальники PG7/PG9/PG11 IP68**, кабель с **drip loop** | Вода не стекает внутрь по жиле | Проверка затяжки весной; нижняя точка петли — ниже сальника |
| **Ориентация:** сальники **снизу**, Gore vent **сверху**; дверь щита открывается **от** потока дождя | Гравитация + вентиляция | — |
| **Козырёк / навес** над щитом | Меньше солнечного нагрева днём и резких перепадов T | — |
| **Обогрев 5–10 W** (кабельный или PTC‑мат, опц.) | Удержание T_internal > T_dew при +5…+10 °C ночью в плечах сезона | Только при повторяющемся конденсате; через реле/термостат, не вплотную к БП |

Чек‑лист после сборки: [01 §5.1](01-overview.md#51-чек-лист-после-сборки) п. 16; типичные проблемы — [01 §5.2](01-overview.md#52-типичные-проблемы-и-решения).

#### 1.3.4. Зимнее хранение щита (демонтаж)

Процедура снятия щита с объекта — [03 §0.1](03-greenhouse-installation.md#01-сезонная-эксплуатация-монтаж-и-демонтаж-щита). Чек‑лист **содержимого щита** перед хранением:

| Шаг | Действие |
|-----|----------|
| 1 | **220 V отключён**, кабель питания отсоединён или смотан отдельно |
| 2 | FTP от полевых линий **отключены на клеммах щита**; на стороне теплицы — **маркировка хвостов** + **заглушки IP68** на сальниках + **drip loop** ([03 §0.1](03-greenhouse-installation.md#01-сезонная-эксплуатация-монтаж-и-демонтаж-щита)) |
| 3 | **Силика‑гель** 50–100 g: свежий или просушенный (индикатор не розовый); контейнер внутри щита |
| 4 | Дверь щита **закрыта**; при длительном хранении — **сухая коробка/кладовая**, t° комнатная, без минусов |
| 5 | **Radxa ZERO 3W** (если есть) — **в том же щите**, питание USB‑C отключено |
| 6 | Антенны U.FL: не откручивать без нужды; при транспортировке — защита SMA от ударов |
| 7 | **Этикетка** на щите: «FTP: см. фото/WAGO‑схема, дата демонтажа» |
| 8 | Опц.: **Gore vent** не заклеивать; при вскрытии весной — осмотр на конденсат, замена геля при необходимости |

NC‑клапаны без питания **закрыты**; при демонтаже щита линии воды на объекте — по вашей гидравлике (ручной кран у входа в теплицу, если оставлен).

### 1.4. Edge SBC для CV (опционально, Phase 1 CV)

Третье вычислительное устройство в щите — **не ESP32**: одноплатник для RTSP‑захвата с PoE‑камер и опционального ONNX inference. Подробнее — [05-computer-vision.md §3.4](05-computer-vision.md#34-edge-sbc-в-щите-ip65).

| Компонент | Кол-во | Цена ★, ₽ | Сумма, ₽ |
|-----------|--------|-----------|----------|
| Radxa ZERO 3W 1 GB / 8 GB eMMC | 1 | 3 500–4 200 | 3 800 |
| USB‑C buck 5 V 3 A (от LRS‑50‑5) | 1 | 300–600 | 450 |
| microSD 32 GB (резерв) | 1 | 400–700 | 500 |

*SBC входит в optional BOM CV ([05 §11](05-computer-vision.md#11-bom-дополнение)), не в базовые ~52 000 ₽.*

---

## 2. Схема подключения
### 2.1. Общие правила монтажа в щите IP65

0. **Место установки:** щит **снаружи теплицы у входа** ([03 §0](03-greenhouse-installation.md#0-щит-снаружи-датчики-и-камеры-внутри)), **только в сезон** (~май–сентябрь); зимой — демонтаж и хранение ([03 §0.1](03-greenhouse-installation.md#01-сезонная-эксплуатация-монтаж-и-демонтаж-щита), [§1.3.4](#134-зимнее-хранение-щита-демонтаж)). Не монтировать внутри объёма с RH 70–95 %.
1. **Разделение питания:** БП 5 В (ESP32, датчики, PCA9685 логика) и БП 12 В (реле, соленоиды) — отдельные Mean Well; общая только «земля» (GND) в одной точке (звезда).
2. **NC‑клапаны:** без питания на катушке — закрыты. Реле **выключено** → клапан закрыт. При пропадании питания ESP32 реле разомкнуты → вода перекрыта.
3. **Flyback:** диод **1N4007** параллельно каждой катушке (реле/сolenoid): катод к «+» 12 В, анод к выходу реле.

   ![1N4007 — выпрямительный диод для защиты от обратной ЭДС катушек реле и соленоидов](images/components/1n4007-diode.jpg)
4. **I2C:** короткие линии в щите; для выноса SHT/BH1750 **внутрь теплицы** — FTP через сальник, SDA/SCL + 5 V + GND, экран на GND в одной точке у ESP32; **drip loop** перед вводом.
5. **OneWire (DS18B20):** экранированная пара, подтяжка 4.7 кΩ к 3.3 V на ESP32.
6. **Поплавок:** NO — замыкание на GND при высоком уровне (или NC — инверсия в ESPHome).
7. **Конденсат:** Gore vent + силика‑гель + ориентация корпуса — [§1.3](04-esp32-and-cabinet.md#13-щит-ip65-снаружи-у-входа--контроллеры-и-питание) (таблица антиконденсата).

---

### 2.2. Распиновка ESP32 №1 — «Полив и бак» (`greenhouse-watering`)

```mermaid
flowchart TB
  subgraph esp1["ESP32 №1 · greenhouse-watering"]
    E1["ESP32-DevKit WROOM-32U"]
  end

  PWR5["LRS-50-5 · 5V"] -->|"5V pin"| E1

  E1 -->|"GPIO4 OneWire"| DS["DS18B20 ×2<br/>бак + линия полива"]
  E1 -->|"GPIO16 INPUT_PULLUP"| FLT["Поплавок уровня → GND"]
  E1 -->|"GPIO13 pulse"| YF1["YF-S201 · полив"]
  E1 -->|"GPIO14 pulse"| YF2["YF-S201 · наполнение бака"]
  E1 -->|"GPIO26 Active HIGH"| R1["Реле · клапан полива"]
  E1 -->|"GPIO27 Active HIGH"| R2["Реле · клапан бака"]
  E1 -.->|"U.FL"| ANT1["Антенна 2.4 GHz"]

  R1 --> V1["Соленоид NC 12V + 1N4007"]
  R2 --> V2["Соленоид NC 12V + 1N4007"]
```

| GPIO | Назначение | Подключение | Примечание |
|------|------------|-------------|------------|
| — | Питание | USB или 5 V на 5V/VIN | От LRS‑50‑5 |
| GPIO4 | OneWire | DS18B20 #1, #2 (бак + линия полива) | Подтяжка 4.7 kΩ |
| GPIO16 | Цифровой вход | Поплавок уровня → GND | `INPUT_PULLUP`, инверсия при NO |
| GPIO13 | Pulse counter | YF‑S201 «полив» (сигнал) | 5 V питание датчика от 5 V БП |
| GPIO14 | Pulse counter | YF‑S201 «наполнение бака» | |
| GPIO26 | Выход реле | IN канал 1 → реле «клапан полива» | Active HIGH |
| GPIO27 | Выход реле | IN канал 2 → реле «клапан наполнения бака» | Active HIGH |
| GPIO21/22 | *Резерв I2C* | Не используются | |
| U.FL | Wi‑Fi | Внешняя антенна 2.4 ГГц | Вынести разъём за металл щита |

**Не использовать:** GPIO6–11 (flash), GPIO34–39 (только вход, без pull-up).

---

### 2.3. Распиновка ESP32 №2 — «Климат и окна» (`greenhouse-climate`)

```mermaid
flowchart TB
  subgraph esp2["ESP32 №2 · greenhouse-climate"]
    E2["ESP32-DevKit WROOM-32U"]
  end

  E2 -->|"GPIO21 SDA · GPIO22 SCL"| BUS1
  E2 -->|"GPIO18 SDA · GPIO19 SCL"| BUS2
  E2 -->|"GPIO4/5/23/25 INPUT_PULLUP"| LIM["Концевики ×4<br/>NC → GND"]
  E2 -->|"3.3 V"| PCA
  E2 -.->|"U.FL"| ANT2["Антенна 2.4 GHz"]

  subgraph BUS1["Шина I2C 1 · GPIO21/22"]
    SHT_TOP["SHT31 центр наверху · 0x44"]
    SHT_ENT["SHT31 вход низ · 0x45"]
    BH_TOP["BH1750 верх · 0x23"]
    PCA["PCA9685 · 0x40"]
  end

  subgraph BUS2["Шина I2C 2 · GPIO18/19"]
    SHT_OPP["SHT31 противоположная · 0x44"]
    BH_PL["BH1750 растения · 0x5C"]
  end

  PWR_SVC["БП 5V ≥3 A"] -->|"V+ силовой"| PCA
  PCA -->|"OUT0 · OUT1"| SERVO["MG996R ×2 → форточки"]
```

| GPIO | Назначение | Подключение | I2C‑адрес |
|------|------------|-------------|-----------|
| GPIO21 | I2C SDA | Шина 1: SHT31×2, BH1750 #1, PCA9685 | — |
| GPIO22 | I2C SCL | Шина 1 | — |
| GPIO18 | I2C SDA | Шина 2: SHT31 #3, BH1750 #2 | — |
| GPIO19 | I2C SCL | Шина 2 | — |
| GPIO4 | Цифровой вход | Концевик «Форточка 1 — закрыта» → GND | `INPUT_PULLUP`, NC, `inverted: true` |
| GPIO5 | Цифровой вход | Концевик «Форточка 1 — открыта» → GND | |
| GPIO23 | Цифровой вход | Концевик «Форточка 2 — закрыта» → GND | |
| GPIO25 | Цифровой вход | Концевик «Форточка 2 — открыта» → GND | |
| — | PCA9685 V+ | Отдельные 5 V 3 A на сервоприводы | Не от USB ESP32 |
| U.FL | Wi‑Fi | Внешняя антенна | |

**Не использовать на ESP32 №2:** GPIO6–11 (flash). GPIO34–39 — только вход без внутренней подтяжки (для концевиков не использовать).

**I2C‑устройства на шине 1 (GPIO21/22):**

| Устройство | ADDR | Зона |
|------------|------|------|
| SHT31 «центр наверху» | 0x44 (ADDR→GND) | Под коньком, ~2,5–3 м |
| SHT31 «вход низ» | 0x45 (ADDR→3.3 V) | У двери, ~1,2 м от пола |
| BH1750 «верх» | 0x23 | Под потолком |
| PCA9685 | 0x40 | Драйвер серво |

**Шина 2 (GPIO18/19):**

| Устройство | ADDR | Зона |
|------------|------|------|
| SHT31 «противоположная сторона» | 0x44 (ADDR→GND) | Дальний торец, ~1,5 м |
| BH1750 «рабочая зона» | 0x5C (ADDR→3.3 V) | Уровень растений |

---

### 2.4. Подключение PCA9685 и сервоприводов MG996R

```mermaid
flowchart LR
  subgraph esp2_pca["ESP32 №2"]
    SDA["GPIO21 SDA"]
    SCL["GPIO22 SCL"]
    GND_E["GND"]
    V33["3.3 V"]
  end

  subgraph pca9685["PCA9685"]
    SDA_P["SDA"]
    SCL_P["SCL"]
    VCC["VCC логика"]
    VP["V+ силовой"]
    OUT0["OUT0"]
    OUT1["OUT1"]
    GND_P["GND"]
  end

  BP5["БП 5V ≥3 A"] --> VP

  SDA --> SDA_P
  SCL --> SCL_P
  V33 --> VCC
  GND_E --> GND_P
  GND_P --> BR_GND["GND серво · коричн."]
  BP5 --> RD_PWR["+5 V серво · красн."]

  OUT0 -->|"PWM 50 Hz"| S1["MG996R · Окно 1<br/>SIG оранж."]
  OUT1 -->|"PWM 50 Hz"| S2["MG996R · Окно 2<br/>SIG оранж."]
```

- Частота PWM для серво в ESPHome: **50 Hz**.
- При двух MG996R под нагрузкой обязателен **отдельный БП 5 V ≥ 3 A** на клемму V+ PCA9685.
- Механика: серво → рычаг → форточка; установить **концевые упоры** и калибровать угол в HA (0° = закрыто, 90° = приоткрыто).

#### Концевики (контроль положения форточек)

На каждую форточку — **два NC‑микропереключателя** (закрыто / открыто). При обрыве провода или отключении ESP32 NC‑контакт разомкнут → `binary_sensor` OFF (безопаснее, чем ложное «закрыто»).

```mermaid
flowchart LR
  subgraph esp2_lim["ESP32 №2 · greenhouse-climate"]
    E2L["GPIO4 · GPIO5 · GPIO23 · GPIO25"]
  end

  subgraph w1["Форточка 1"]
    S1C["Концевик закрыто<br/>NC → GPIO4 · GND"]
    S1O["Концевик открыто<br/>NC → GPIO5 · GND"]
  end

  subgraph w2["Форточка 2"]
    S2C["Концевик закрыто<br/>NC → GPIO23 · GND"]
    S2O["Концевик открыто<br/>NC → GPIO25 · GND"]
  end

  E2L --> S1C
  E2L --> S1O
  E2L --> S2C
  E2L --> S2O
```

ASCII (монтаж на объекте):

```
Форточка 1:  [GPIO4]─── NC концевик «закрыто» ─── GND
             [GPIO5]─── NC концевик «открыто»  ─── GND
Форточка 2:  [GPIO23]── NC концевик «закрыто» ─── GND
             [GPIO25]── NC концевик «открыто»  ─── GND
```

| GPIO | ID (ESPHome) | Friendly name |
|------|--------------|---------------|
| GPIO4 | `limit_w1_closed` | Форточка 1 — закрыта (концевик) |
| GPIO5 | `limit_w1_open` | Форточка 1 — открыта (концевик) |
| GPIO23 | `limit_w2_closed` | Форточка 2 — закрыта (концевик) |
| GPIO25 | `limit_w2_open` | Форточка 2 — открыта (концевик) |

**Монтаж:** крепить концевик так, чтобы рычаг форточки **нажимал** переключатель только в крайнем положении. Проводка — в FTP‑кабеле вместе с питанием серво (отдельная пара на каждый концевик: сигнал + GND). Подтяжка — `INPUT_PULLUP` в ESPHome, `inverted: true` (как поплавок бака на ESP32 №1).

**Логика** (`esphome/greenhouse-climate.yaml`, параметры `vent_move_timeout_ms: 8000`, `vent_idle_mismatch_ms: 30000`):

| Событие | Условие | Действие |
|---------|---------|----------|
| Команда OPEN/CLOSE / position 0 или 100 % | Серво отработало, прошло 8 с | Ожидаемый концевик должен быть ON; иначе `binary_sensor` «ошибка положения» |
| Промежуточное положение (например 40 %) | Угол 5–85° | Концевики не проверяются |
| Простой | Угол ≤ 5° или ≥ 85°, несовпадение с концевиками 30 с | «ошибка положения» → ON; HA шлёт уведомление |

---

### 2.5. Схема «откуда → куда» (щит IP65)

**Распределение питания** (5 V логика и 12 V нагрузки — отдельные БП, общая звезда GND):

```mermaid
flowchart TB
  AC["220 V AC"] --> AUT["Автомат 10 A"]
  AUT --> LRS5["Mean Well LRS-50-5 · 5 V"]
  AUT --> LRS12["Mean Well LRS-100-12 · 12 V"]

  subgraph LOGIC["5 V · логика и датчики"]
    LRS5 --> ESP1_PWR["ESP32 №1 · 5V pin"]
    LRS5 --> ESP2_PWR["ESP32 №2 · 5V pin"]
    LRS5 --> YF_PWR["YF-S201 ×2 · 5V"]
    LRS5 --> PCA_LOGIC["PCA9685 VCC · логика"]
    LRS5 --> SBC_PWR["Edge SBC · USB-C buck 5V 2A<br/>greenhouse-cv-edge · .13"]
  end

  subgraph LOAD12["12 V · реле и соленоиды"]
    LRS12 --> REL_PWR["Реле VCC/JD-VCC 12V ×2"]
    LRS12 --> UPS["Mini UPS 12V опц."]
    UPS --> REL_PWR
    REL_PWR --> SOL["Катушки NC + 1N4007"]
  end

  STAR["Звезда GND · WAGO 221"]
  LRS5 -.-> STAR
  LRS12 -.-> STAR
  ESP1_PWR -.-> STAR
  ESP2_PWR -.-> STAR
```

**Сигнальные и силовые связи** (щит **снаружи** → FTP/Cat6 **в теплицу**):

```mermaid
flowchart LR
  subgraph outdoor["Снаружи у входа"]
    subgraph shield["Щит IP65"]
      E1["ESP32 №1"]
      E2["ESP32 №2"]
      SBC["Edge SBC · CV"]
      REL["Реле ×2"]
      PCA["PCA9685"]
    end
    ANT["Антенны · U.FL"]
    GORE["Gore vent"]
  end

  subgraph gh["Теплица · RH 70–95 %"]
    HYDR["DS18B20 · YF-S201 · поплавок · клапаны"]
    CLIM["SHT31 · BH1750"]
    WIN["MG996R · концевики"]
    CAM["PoE камеры CV"]
  end

  E1 -->|"GPIO26/27"| REL
  REL --> HYDR
  E1 -->|"GPIO4/13/16"| HYDR
  E2 -->|"I2C1/2"| CLIM
  E2 -->|"GPIO4/5/23/25"| WIN
  PCA --> WIN
  CAM -->|"Cat6 · drip loop"| POE["PoE · домашний шкаф"]
  SBC -.->|"Wi‑Fi RTSP"| CAM
  E1 -.-> ANT
  E2 -.-> ANT
  GORE -.-> shield
```

ASCII:

```
[Щит IP65 · снаружи] ──FTP──► [внутри: SHT31, BH1750, клапаны, серво, YF-S201, DS18B20]
                    ──Wi‑Fi──► Stellar 6
[PoE шкаф дом] ──Cat6──► [камеры внутри теплицы]     Edge SBC (в щите) ← RTSP по LAN/Wi‑Fi
```

> Электрическая часть ESP32 №1 — [§2.2](04-esp32-and-cabinet.md#22-распиновка-esp32-1--полив-и-бак-greenhouse-watering). **Гидравлическая разводка** (кран → бак → капельный полив) — [§2.6](03-greenhouse-installation.md#26-гидравлическая-схема-водоснабжения-и-полива).

---

## 4. Прошивка и интеграция
### 4.1. Подготовка ESPHome

1. Home Assistant → **Настройки** → **Устройства и службы** → **Добавить интеграцию** → **ESPHome**.
2. Установить add-on **ESPHome** (если ещё нет).
3. Прошивка: USB первичная → далее OTA по Wi‑Fi.

Файлы конфигурации рекомендуется хранить в репозитории:

```
smart-greenhouse/
  esphome/
    greenhouse-watering.yaml
    greenhouse-climate.yaml
```

---

### 4.2. ESPHome — ESP32 №1 «Полив и бак»

```yaml
esphome:
  name: greenhouse-watering
  friendly_name: "Теплица — полив и бак"
  name_add_mac_suffix: false

esp32:
  board: esp32dev
  framework:
    type: arduino

logger:
  level: INFO

api:
  encryption:
    key: !secret api_encryption_key

ota:
  - platform: esphome
    password: !secret ota_password

wifi:
  ssid: !secret wifi_ssid_iot
  password: !secret wifi_password_iot
  fast_connect: true
  power_save_mode: none
  manual_ip:
    static_ip: 192.168.30.11
    gateway: 192.168.30.1
    subnet: 255.255.255.0
  # После первого подключения раскомментируйте BSSID ближайшей Mesh-точки:
  # bssid: "XX:XX:XX:XX:XX:XX"
  ap:
    ssid: "Greenhouse-Water Fallback"
    password: !secret ap_fallback_password

captive_portal:

sensor:
  - platform: wifi_signal
    name: "Полив — RSSI"
    id: wifi_rssi
    update_interval: 60s

  - platform: dallas_temp
    one_wire_id: bus_onewire
    name: "Бак — температура воды"
    id: tank_water_temp
    filters:
      - sliding_window_moving_average:
          window_size: 5
          send_every: 5

  - platform: dallas_temp
    one_wire_id: bus_onewire
    address: 0x000000000000  # заменить на реальный ROM после первого скана
    name: "Полив — температура воды"
    id: irrigation_water_temp

  - platform: pulse_counter
    pin:
      number: GPIO13
      mode: INPUT_PULLUP
    name: "Полив — расход"
    id: flow_irrigation
    unit_of_measurement: "L/min"
    accuracy_decimals: 2
    filters:
      - multiply: 0.00222  # YF-S201: ~450 имп/л → L/min (калибровать!)
    update_interval: 1s

  - platform: pulse_counter
    pin:
      number: GPIO14
      mode: INPUT_PULLUP
    name: "Бак — расход наполнения"
    id: flow_tank_fill
    unit_of_measurement: "L/min"
    accuracy_decimals: 2
    filters:
      - multiply: 0.00222
    update_interval: 1s

binary_sensor:
  - platform: gpio
    pin:
      number: GPIO16
      mode: INPUT_PULLUP
      inverted: true
    name: "Бак — высокий уровень"
    id: tank_level_high
    device_class: moisture

switch:
  - platform: gpio
    pin: GPIO26
    name: "Клапан полива"
    id: valve_irrigation
    restore_mode: ALWAYS_OFF
    icon: "mdi:sprinkler"

  - platform: gpio
    pin: GPIO27
    name: "Клапан наполнения бака"
    id: valve_tank_fill
    restore_mode: ALWAYS_OFF
    icon: "mdi:water-pump"

one_wire:
  - platform: gpio
    pin: GPIO4
    id: bus_onewire

interval:
  - interval: 5min
    then:
      - if:
          condition:
            lambda: 'return id(wifi_rssi).state < -85;'
          then:
            - logger.log: "RSSI низкий, перезагрузка Wi-Fi"
            - wifi.disable:
            - delay: 5s
            - wifi.enable:
```

---

### 4.3. ESPHome — ESP32 №2 «Климат и окна»

```yaml
esphome:
  name: greenhouse-climate
  friendly_name: "Теплица — климат и окна"
  name_add_mac_suffix: false

esp32:
  board: esp32dev
  framework:
    type: arduino

logger:
  level: INFO

api:
  encryption:
    key: !secret api_encryption_key

ota:
  - platform: esphome
    password: !secret ota_password

wifi:
  ssid: !secret wifi_ssid_iot
  password: !secret wifi_password_iot
  fast_connect: true
  power_save_mode: none
  manual_ip:
    static_ip: 192.168.30.12
    gateway: 192.168.30.1
    subnet: 255.255.255.0
  ap:
    ssid: "Greenhouse-Climate Fallback"
    password: !secret ap_fallback_password

captive_portal:

i2c:
  - id: bus_main
    sda: GPIO21
    scl: GPIO22
    scan: true
  - id: bus_secondary
    sda: GPIO18
    scl: GPIO19
    scan: true

sensor:
  - platform: wifi_signal
    name: "Климат — RSSI"
    id: wifi_rssi
    update_interval: 60s

  - platform: sht3xd
    i2c_id: bus_main
    address: 0x44
    update_interval: 30s
    temperature:
      name: "Теплица центр наверху — температура"
      id: temp_center_top
    humidity:
      name: "Теплица центр наверху — влажность"
      id: hum_center_top

  - platform: sht3xd
    i2c_id: bus_main
    address: 0x45
    update_interval: 30s
    temperature:
      name: "Теплица вход низ — температура"
      id: temp_entrance_low
    humidity:
      name: "Теплица вход низ — влажность"
      id: hum_entrance_low

  - platform: sht3xd
    i2c_id: bus_secondary
    address: 0x44
    update_interval: 30s
    temperature:
      name: "Теплица противоположная сторона — температура"
      id: temp_opposite
    humidity:
      name: "Теплица противоположная сторона — влажность"
      id: hum_opposite

  - platform: bh1750
    i2c_id: bus_main
    address: 0x23
    name: "Освещённость потолок"
    id: lux_ceiling
    update_interval: 60s

  - platform: bh1750
    i2c_id: bus_secondary
    address: 0x5C
    name: "Освещённость растения"
    id: lux_plants
    update_interval: 60s

  - platform: template
    name: "Теплица — средняя температура"
    id: temp_avg
    unit_of_measurement: "°C"
    lambda: |-
      return (id(temp_entrance_low).state + id(temp_opposite).state +
              id(temp_center_top).state) / 3.0;
    update_interval: 30s

  - platform: template
    name: "Теплица — средняя влажность"
    id: hum_avg
    unit_of_measurement: "%"
    lambda: |-
      return (id(hum_entrance_low).state + id(hum_opposite).state +
              id(hum_center_top).state) / 3.0;
    update_interval: 30s

pca9685:
  - id: pca9685_hub
    address: 0x40
    frequency: 50 Hz

output:
  - platform: pca9685
    id: pwm_window_1
    pca9685_id: pca9685_hub
    channel: 0
    min_power: 4.5%
    max_power: 10.5%

  - platform: pca9685
    id: pwm_window_2
    pca9685_id: pca9685_hub
    channel: 1
    min_power: 4.5%
    max_power: 10.5%

number:
  - platform: template
    name: "Окно 1 — угол"
    id: window_1_angle
    min_value: 0
    max_value: 90
    step: 1
    unit_of_measurement: "°"
    optimistic: true
    set_action:
      - servo.write:
          id: servo_window_1
          level: !lambda 'return x / 90.0;'

  - platform: template
    name: "Окно 2 — угол"
    id: window_2_angle
    min_value: 0
    max_value: 90
    step: 1
    unit_of_measurement: "°"
    optimistic: true
    set_action:
      - servo.write:
          id: servo_window_2
          level: !lambda 'return x / 90.0;'

servo:
  - id: servo_window_1
    output: pwm_window_1
    auto_detach: false

  - id: servo_window_2
    output: pwm_window_2
    auto_detach: false

cover:
  - platform: template
    name: "Форточка 1"
    id: vent_window_1
    has_position: true
    optimistic: true
    open_action:
      - number.set:
          id: window_1_angle
          value: 90
    close_action:
      - number.set:
          id: window_1_angle
          value: 0
    set_position_action:
      - number.set:
          id: window_1_angle
          value: !lambda 'return x * 90;'

  - platform: template
    name: "Форточка 2"
    id: vent_window_2
    has_position: true
    optimistic: true
    open_action:
      - number.set:
          id: window_2_angle
          value: 90
    close_action:
      - number.set:
          id: window_2_angle
          value: 0
    set_position_action:
      - number.set:
          id: window_2_angle
          value: !lambda 'return x * 90;'

interval:
  - interval: 5min
    then:
      - if:
          condition:
            lambda: 'return id(wifi_rssi).state < -85;'
          then:
            - wifi.disable:
            - delay: 5s
            - wifi.enable:
```

**Файл секретов** (`esphome/secrets.yaml`, не коммитить в git):

```yaml
wifi_ssid_iot: "IoT-GH"
wifi_password_iot: "ваш-длинный-пароль"
api_encryption_key: "сгенерировать через esphome secrets"
ota_password: "ваш-ota-пароль"
ap_fallback_password: "резервный-ap"
```

---

### 4.4. Добавление устройств в Home Assistant

1. ESPHome add-on → **+ New Device** → импорт YAML или wizard.
2. Первая прошивка по USB (ESP32 подключён к ПК с HA / esphome run).
3. После появления в сети `IoT-GH` — устройства автоматически обнаружатся (**ESPHome** → **Configure** → ввести ключ шифрования API).
4. Проверить **Настройки → Устройства** — два устройства ESPHome.

**Ожидаемые сущности:**

| Устройство | Сущности (entity_id*) |
|------------|----------------------|
| greenhouse-watering | `sensor.greenhouse_watering_bak_temperatura_vody`, `sensor.greenhouse_watering_poliv_rashod`, `binary_sensor.greenhouse_watering_bak_vysokiy_uroven`, `switch.greenhouse_watering_klapan_poliva`, `switch.greenhouse_watering_klapan_napolneniya_baka`, `sensor.greenhouse_watering_poliv_rssi` |
| greenhouse-climate | `sensor.teplitsa_vkhod_niz_temperatura`, `sensor.teplitsa_tsentr_naverkhu_temperatura`, `sensor.teplitsa_max_temperatura`, `sensor.teplitsa_srednyaya_vlazhnost`, `sensor.osveshchennost_potolok`, `cover.fortochka_1`, `cover.fortochka_2`, `text_sensor.teplitsa_zona_max_temperatury`, … |

\* Точные `entity_id` зависят от версии HA; переименуйте в **Настройки → Устройства → Сущность → Имя**.

---


---

← [03-greenhouse-installation](03-greenhouse-installation.md) | [Оглавление](smart-greenhouse-design.md)

---

