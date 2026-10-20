# Weather and production history

Provider: https://open-meteo.com/en/docs (CC BY 4.0).
Current conditions are model-based at 15-minute resolution, not instantaneous
measurements from the AWG. The app refreshes every 15 minutes while open and on
resume. Past rows use hourly model averages for humidity and temperature and
the most frequent hourly weather code. Today uses current conditions.

Use **Use my location for AWG** while near the machine. This requests foreground
location permission, rounds coordinates to two decimals, and saves a fixed
weather location. It does not follow the phone afterward. The location is sent
to Open-Meteo. Permission denial and network errors leave the app usable.

Firebase paths:

- `AWG/weatherLocation/latitude`, `longitude`, `updatedAt`: created by the button.
- `AWG/weatherApiByDate/YYYY-MM-DD`: saved automatically by the app, including
  `humidity`, `temperature`, `weatherCode`, `source`, `aggregation`, `fetchedAt`,
  and `observedAt` for current conditions. Wind speed is in km/h where present.
- `AWG/weatherByDate/YYYY-MM-DD`: optional existing recorded weather; API data
  takes priority in this table. These records are never overwritten by the API.
- `AWG/productionByDate/YYYY-MM-DD`: actual liters collected on that Philippine
  calendar date. This remains the responsibility of the ESP32/backend. The app
  never derives water production from weather or writes invented yields.

Firebase rules must permit your app's existing identity to read the location
and history, and write the weather location and API history. No rules have been
changed. Do not make the whole database public. No API key is needed for the
Open-Meteo non-commercial endpoint; commercial use requires checking its terms.

Humidity labels (no RH suffix): Excellent 80–100%, Optimal 70–<80%, Moderate
45–<70%, Low <45%. The requested 45–49 and >90 gaps are included in Moderate and
Excellent respectively. These are display classifications, not validated AWG
capacity guarantees. Rain/cloud/sun icons follow weather codes; wind overrides
clear/cloud conditions at 25 km/h or higher. Weather is not inferred from humidity.

History is rolling seven days, newest first, in UTC+8. Missing readings remain
missing. Automatic retrieval runs only while the app is open; use a backend
scheduled job if unattended permanent collection is required.
