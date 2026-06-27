<%@ page language="java" contentType="application/xhtml+xml; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %><%@ page import="java.util.*, java.io.*, java.nio.charset.StandardCharsets, java.time.*, java.time.format.*" %><%@ page import="org.json.JSONObject, org.json.JSONArray" %><%!
public String normMac(String mac) {
    if (mac == null) return "UNKNOWN";
    return mac.replaceAll("[:\\-]", "").toUpperCase().trim();
}
%><%
    // KORREKTUR: Erzwingt das XML-Tag unanfechtbar in Zeile 1, Byte 0 (Behebt Telefon-Parserabsturz)
    out.print("<?xml version=\"1.0\" encoding=\"utf-8\"?>\n");

    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setContentType("application/xhtml+xml; charset=UTF-8");

    String macClean = normMac(request.getParameter("mac"));
    String hsId = request.getParameter("handsetid");
    if (hsId == null) hsId = "1";

    String cityName = "WETTER";
    JSONArray weatherArray = null;
    String debugInfo = "";

    try {
        // ---------------- CONFIG ----------------
        String configPath = application.getRealPath("/WEB-INF/config.json");
        File confFile = new File(configPath);

        if (confFile.exists()) {
            JSONObject cfg = new JSONObject(
                new String(java.nio.file.Files.readAllBytes(confFile.toPath()), StandardCharsets.UTF_8)
            );
            JSONObject gws = cfg.optJSONObject("gateways");
            if (gws != null && gws.has(macClean)) {
                JSONObject hs = gws.getJSONObject(macClean).optJSONObject("handsets").optJSONObject(hsId);
                if (hs != null) {
                    cityName = hs.optString("city", "WETTER");
                }
            }
        }

        // ---------------- CACHE ----------------
        String cacheName = "cache_" + macClean + ".json";
        File cacheFile = new File(application.getRealPath("/WEB-INF/" + cacheName));
        debugInfo += "CACHE: " + cacheFile.getAbsolutePath() + "<br/>";

        if (cacheFile.exists()) {
            String json = new String(java.nio.file.Files.readAllBytes(cacheFile.toPath()), StandardCharsets.UTF_8);
            JSONObject root = new JSONObject(json);
            JSONObject handsets = root.optJSONObject("handsets");

            if(handsets != null){
                debugInfo += "HANDSETS:<br/>";
                Iterator<String> keys = handsets.keys();
                while(keys.hasNext()){
                    String k = keys.next();
                    debugInfo += k + "<br/>";
                }
                keys = handsets.keys();
                if(keys.hasNext()){
                    String firstKey = keys.next();
                    JSONObject hs = handsets.optJSONObject(firstKey);
                    if(hs != null){
                        weatherArray = hs.optJSONArray("weather");
                        cityName = hs.optString("city", cityName);
                    }
                }
            }
            if(weatherArray != null){
                debugInfo += "CACHE OK (" + weatherArray.length() + " Einträge)<br/>";
            }else{
                debugInfo += "KEIN WEATHER ARRAY<br/>";
            }
        } else {
            debugInfo += "CACHE FEHLT<br/>";
        }
    } catch (Exception e) {
        debugInfo += "ERROR: " + e.getMessage();
    }

    String displayCity = cityName
        .replace("ü","UE")
        .replace("ä","AE")
        .replace("ö","OE")
        .replace("ß","SS")
        .toUpperCase();
%><%!
public String clean(String t) {
    if (t == null || t.trim().isEmpty()) return "Heiter";
    String r = t.toLowerCase();
    if (r.contains("thunder") || r.contains("bolt")) return "Gewitter";
    if (r.contains("rain") || r.contains("shower")) return "Regen";
    if (r.contains("drizzle")) return "Niesel";
    if (r.contains("snow")) return "Schnee";
    if (r.contains("clear") || r.contains("sun")) return "Sonnig";
    if (r.contains("cloud")) return "Wolkig";
    if (r.contains("fog") || r.contains("mist")) return "Nebel";
    if (r.contains("wind")) return "Windig";
    if (r.contains("dry")) return "Heiter";
    return "Heiter";
}
%>
<!-- KORREKTUR: Vollständige DTD-URL für strikte Gigaset-XML-Validität -->
<!DOCTYPE html PUBLIC "-//WAPFORUM//DTD XHTML Mobile 1.0//EN" "http://wapforum.org">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <title><%= displayCity %></title>
    <!-- KORREKTUR: Saubere Proxy-Stamm-Zuweisung passend zu deiner web.xml-Ordnerstruktur -->
    <meta name="imageproxy" content="http://gigaset.net" />
</head>
<body bgcolor="#ffffff">

<% if (weatherArray != null && weatherArray.length() > 0) { %>
<%
    LocalDate today = LocalDate.now();
    DateTimeFormatter dtfDay = DateTimeFormatter.ofPattern("E", Locale.GERMAN);

    for (int d = 0; d < 3; d++) {
        String target = today.plusDays(d).toString();
        JSONObject dayEntry = null;
        JSONObject nightEntry = null;

        for (int i = 0; i < weatherArray.length(); i++) {
            JSONObject e = weatherArray.getJSONObject(i);
            String ts = e.optString("timestamp");
            if (ts.startsWith(target)) {
                if (ts.contains("T12:00")) dayEntry = e;
                if (ts.contains("T03:00")) nightEntry = e;
            }
        }

        if (dayEntry == null) {
            for (int i = 0; i < weatherArray.length(); i++) {
                JSONObject e = weatherArray.getJSONObject(i);
                if (e.optString("timestamp").startsWith(target)) {
                    dayEntry = e;
                    break;
                }
            }
        }

        if (dayEntry != null) {
            int tD = (int)Math.round(dayEntry.optDouble("temperature", 0));
            int tN = nightEntry != null
                ? (int)Math.round(nightEntry.optDouble("temperature", tD - 5))
                : (tD - 5);

            String cond = clean(dayEntry.optString("condition"));
            String label = (d == 0) ? "Heute" : today.plusDays(d).format(dtfDay);

            // Holt den rohen Zustand für das dynamische Datei-Mapping
            String rawCondition = dayEntry.optString("condition", "sun").toLowerCase();
            
            // KORREKTUR: Ermittelt den fragezeichenfreien, virtuellen BMP-Dateinamen
            String virtualIconFile = "sun.bmp";
            if (rawCondition.contains("cloud")) { virtualIconFile = "cloud.bmp"; }
            else if (rawCondition.contains("rain") || rawCondition.contains("shower") || rawCondition.contains("drizzle")) { virtualIconFile = "rain.bmp"; }
            else if (rawCondition.contains("snow")) { virtualIconFile = "snow.bmp"; }
            else if (rawCondition.contains("thunder") || rawCondition.contains("bolt")) { virtualIconFile = "thunder.bmp"; }
%>
<p style="text-align:center;">
    
    <%= label %><br/>
    <%= cond %>&nbsp; <%= tD %>°C/<%= tN %>°C
</p>
<%      }
    }
%>
<% } else { %>
<p style="text-align:center;">
Lade Daten...<br/>
<%= debugInfo %>
</p>
<% } %>
</body>
</html>
