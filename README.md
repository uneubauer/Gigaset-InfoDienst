# Gigaset info.gigaset.net Server Rebirth

Ein vollständiger, modularer Server-Nachbau für die abgeschalteten Gigaset Info-Center- und Screensaver-Dienste. Dieses Projekt erweckt interaktive Wetter-Anzeigen und Screensaver-Icons auf Consumer- (GO-Box 100 / COMFORT 550 HX) und Enterprise-Endgeräten (N510 IP PRO / SL750H PRO) im Mischbetrieb zu neuem Leben.

## Features

- **Feste Städte-Zuweisung**: Liest die Zielorte für jedes Mobilteil direkt aus einer strukturierten `config.json` aus. Perfekt für den dedizierten Betrieb an festen Standorten ohne mühsame Tastatureingaben am Telefon.
- **Intelligente Handset-Weiche**: Vollautomatischer JSON-Fallback. Erkennt die übermittelten Hardware-Seriennummern (Handset-IDs) der Mobilteile aus der `config.json` und schützt vor Endlos-Ladeschleifen, indem bei unbekannten IDs automatisch das erste verfügbare Mobilteil der Basis geladen wird.
- **Manueller Low-Level-BMP-Streamer**: Umgeht die fehlerhafte Standard-Kompression von Javas `ImageIO.write()`. Der Bild-Proxy baut die Dateistruktur (54-Byte-Header, Farbkanäle, Zeilen-Padding) byteweise von Hand als echtes, unkomprimiertes **Bottom-Up-Windows-BMP** (24-Bit BGR) auf.
- **Auto-Skalierung per User-Agent**: Erkennt das anfragende System zur Laufzeit. Liefert für Consumer-Geräte (GO-Box) ressourcenschonende 32x32px Icons, während für Pro-Systeme (N510) scharfe 128x128px Grafiken generiert werden, um RAM-Limits der Firmware einzuhalten.
- **MikroTik- & Reverse-Proxy-Sicher**: Optimierte Routing-Architektur ohne unzulässige HTTPS/TLS-Zwangssteuerungen oder restriktive Content Security Policies (CSP), welche von älteren Handset-Browsern blockiert werden.

---

## System-Architektur & Datenfluss

```text
[Gigaset Mobilteil] (Ruhezustand / Screensaver)
       │
       ▼ (HTTP Request: http://gigaset.net)
[MikroTik RB5009] (Fängt DNS statisch ab -> leitet weiter an Tomcat-IP)
       │
       ▼ (Port 80 / Unverschlüsseltes HTTP)
[Tomcat / web.xml] (Maskiert virtuelles Pfad-Mapping zu image_proxy.jsp)
       │
       ▼ (User-Agent Analyse: GO-Box = 32x32px / N510 PRO = 128x128px)
[image_proxy.jsp] (Schneidet Spritesheet -> baut Byte-Header -> Stream)
```

---

## Installations- & Konfigurationsanleitung

### 1. Router-Setup (MikroTik RB5009)
Da die Telefone hartcodiert nach der originalen Domain verlangen, muss der RB5009 die Anfragen im lokalen Netz abfangen. Führe folgende Befehle im Router-Terminal aus:

```routeros
# Erstellt eine unumgehbare RegEx-Regel für alle .net Anfragen des Telefons auf deine Tomcat-IP (z.B. 192.168.88.8)
/ip dns static add regexp=".*\\.gigaset\\.net\$|gigaset\\.net\$" address=192.168.88.8 comment="Gigaset Net Abfangjaeger"

# Leert den internen DNS-Zwischenspeicher des Routers
/ip dns cache flush
```

*Hinweis: Da die NAT-Regel für Port 80 im RB5009 von oben nach unten abgearbeitet wird, muss sie zwingend auf Position 0 verschoben werden (`/ip firewall nat move 34 0`), um vor globalen Port-Weiterleitungen (z.B. für Zoraxy) zu greifen.*

### 2. Servlet-Mapping (`WEB-INF/web.xml`)
Der integrierte Screensaver-Parser blockiert dynamische URLs mit Fragezeichen (`?data=`). Um dies zu umgehen, spiegelt die `web.xml` statische, fragezeichenfreie `.bmp`-Pfade direkt auf den Java-Bilderdienst:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<web-app xmlns="https://jakarta.ee" version="5.0">
    
    <servlet>
        <servlet-name>WeatherService</servlet-name>
        <jsp-file>/weather.jsp</jsp-file>
    </servlet>
    <servlet-mapping>
        <servlet-name>WeatherService</servlet-name>
        <url-pattern>/info/request.do</url-pattern>
    </servlet-mapping>

    <servlet>
        <servlet-name>ImageService</servlet-name>
        <jsp-file>/image_proxy.jsp</jsp-file>
    </servlet>
    <!-- Virtuelle Pfade für den stabilen Screensaver-RAM-Load ohne Query-Strings -->
    <servlet-mapping><servlet-name>ImageService</servlet-name><url-pattern>/info/sun.bmp</url-pattern></servlet-mapping>
    <servlet-mapping><servlet-name>ImageService</servlet-name><url-pattern>/info/cloud.bmp</url-pattern></servlet-mapping>
    <servlet-mapping><servlet-name>ImageService</servlet-name><url-pattern>/info/rain.bmp</url-pattern></servlet-mapping>
    <servlet-mapping><servlet-name>ImageService</servlet-name><url-pattern>/info/snow.bmp</url-pattern></servlet-mapping>
    <servlet-mapping><servlet-name>ImageService</servlet-name><url-pattern>/info/thunder.bmp</url-pattern></servlet-mapping>

    <mime-mapping>
        <extension>jsp</extension>
        <mime-type>application/xhtml+xml</mime-type>
    </mime-mapping>
</web-app>
```

### 3. Dateistruktur im Tomcat-Server
Stelle sicher, dass deine Applikation als **Root-Applikation** (`webapps/ROOT/`) betrieben wird, um relative Pfadabbrüche der Handsets zu verhindern.

```text
webapps/ROOT/
├── WEB-INF/
│   ├── web.xml
│   ├── config.json         <-- Enthält deine Gateways und Handset-IDs
│   └── cache_[MAC].json    <-- Gespeicherte Wetterdaten deiner API
├── static/
│   └── icons/
│       └── _spritesheet.png
├── weather.jsp             <-- Generiert den XHTML-Text & <object> Tags
└── image_proxy.jsp         <-- Verarbeitet den manuellen Binär-BMP-Stream
```

---

## Technische Besonderheiten & Fallstricke

- **Whitespace-Sperre**: Vor dem XML-Prolog (`<?xml...`) darf in JSP-Dateien kein einziges Byte Leerzeichen stehen. Der Code nutzt `out.print("<?xml...")` direkt auf Byte-Position 0, um Parser-Abstürze der Handsets zu verhindern.
- **HSTS-Falle am PC**: Moderne PC-Browser erzwingen beim Testen oft heimlich HTTPS (`https://gigaset.net`), wodurch du auf der öffentlichen Werbeseite landest. Die Telefone nutzen reines HTTP auf Port 80 und landen dank der MikroTik-NAT-Regel exakt im lokalen Tomcat.
- **Speicher-Reset**: Nach jeder Konfigurationsänderung müssen alle Basisstationen (GO-Box / N510 PRO) zwingend für **10 Sekunden vom Stromnetz getrennt werden**, um den extrem hartnäckigen internen DNS- und Image-Cache der Handsets zu leeren.

---

## Lizenz

Dieses Projekt ist unter der MIT-Lizenz lizenziert - freie Nutzung für alle Gigaset-Enthusiasten, um die hervorragende Hardware vor dem Elektromüll zu bewahren.
