# Gigaset info.gigaset.net Server Rebirth

Ein vollständiger, modularer Server-Nachbau für die abgeschalteten Gigaset Info-Center- und Screensaver-Dienste. Dieses Projekt erweckt interaktive Wetter-Anzeigen und Screensaver-Icons auf Consumer- (GO-Box 100 / COMFORT 550 HX) und Enterprise-Endgeräten (N510 IP PRO / SL750H PRO) im Mischbetrieb zu neuem Leben.

## Über dieses Projekt (About)

Nach der offiziellen Abschaltung der Gigaset.net-Infrastruktur wurden viele hochwertige VoIP-Telefone ihrer interaktiven Funktionen beraubt. Im Ruhezustand (Screensaver) blieb das Display weiß oder zeigte Verbindungsfehler. 

Dieses Projekt bietet eine serverbasierte Rebirth-Lösung in Java/JSP. Da die Hardware-Plattformen von Gigaset extrem strikte XML-Parser besitzen und im Ruhezustand keine dynamischen URLs (`?parameter=`) oder moderne Bildkompressionen verarbeiten können, bricht dieses Repository die Logik auf ein byte-perfektes, unkomprimiertes Binär-Level herunter. Es dient als Brücke, um exzellente Hardware vor dem vorzeitigen Elektromüll zu bewahren.

## Features

- **Feste Städte-Zuweisung**: Liest die Zielorte für jedes Mobilteil direkt aus einer strukturierten `config.json` aus. Perfekt für den dedizierten Betrieb an festen Standorten ohne mühsame Tastatureingaben am Telefon.
- **Intelligente Handset-Weiche**: Vollautomatischer JSON-Fallback. Erkennt die übermittelten Hardware-Seriennummern (Handset-IDs) der Mobilteile aus der `config.json` und schützt vor Endlos-Ladeschleifen, indem bei unbekannten IDs automatisch das erste verfügbare Mobilteil der Basis geladen wird.
- **Manueller Low-Level-BMP-Streamer**: Umgeht die fehlerhafte Standard-Kompression von Javas `ImageIO.write()`. Der Bild-Proxy baut die Dateistruktur (54-Byte-Header, Farbkanäle, Zeilen-Padding) byteweise von Hand als echtes, unkomprimiertes **Bottom-Up-Windows-BMP** (24-Bit BGR) auf.
- **Auto-Skalierung per User-Agent**: Erkennt das anfragende System zur Laufzeit. Liefert für Consumer-Geräte (GO-Box) ressourcenschonende 32x32px Icons, während für Pro-Systeme (N510) scharfe 128x128px Grafiken generiert werden, um RAM-Limits der Firmware einzuhalten.
- **MikroTik- & Reverse-Proxy-Sicher**: Optimierte Routing-Architektur ohne unzulässige HTTPS/TLS-Zwangssteuerungen oder restriktive Content Security Policies (CSP), welche von älteren Handset-Browsern blockiert werden.
