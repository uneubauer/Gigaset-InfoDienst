<%@ page language="java" contentType="application/xhtml+xml; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %>
<%@ page import="java.io.*, org.json.*, java.nio.charset.StandardCharsets" %>
<%
    // 1. IDs auslesen
    String mac = request.getParameter("mac");
    String hsId = request.getParameter("handsetid");

    if (mac == null || mac.isEmpty()) mac = "unknown";
    if (hsId == null || hsId.isEmpty()) hsId = "1";

    String aktuellerOrt = "Nicht konfiguriert";

    try {
        String configPath = application.getRealPath("/WEB-INF/config.json");
        File configFile = new File(configPath);

        if (configFile.exists()) {
            String content = new String(java.nio.file.Files.readAllBytes(configFile.toPath()), StandardCharsets.UTF_8);
            JSONObject configJson = new JSONObject(content);

            // NEUE STRUKTUR PRÜFEN: gateways -> MAC -> handsets -> ID
            if (configJson.has("gateways")) {
                JSONObject gateways = configJson.getJSONObject("gateways");
                if (gateways.has(mac)) {
                    JSONObject thisGateway = gateways.getJSONObject(mac);
                    if (thisGateway.has("handsets")) {
                        JSONObject handsets = thisGateway.getJSONObject("handsets");
                        if (handsets.has(hsId)) {
                            JSONObject currentHs = handsets.getJSONObject(hsId);
                            // Wir nehmen den Key "city", den wir in weather_save.jsp nutzen
                            aktuellerOrt = currentHs.optString("city", "Ort unbekannt");
                        }
                    }
                }
            } else {
                aktuellerOrt = "Keine Daten hinterlegt";
            }
        } else {
            aktuellerOrt = "Config fehlt";
        }
    } catch (Exception e) {
        aktuellerOrt = "Fehler im JSON";
    }
%><?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//OMA//DTD XHTML Mobile 1.2//EN" "http://www.openmobilealliance.org/tech/DTD/xhtml-mobile12.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <title>Wetter</title>
</head>
<body>
    <ul>
        <li><b><%= aktuellerOrt %></b></li>
        
        <li><a href="weather_search.jsp?mac=<%= mac %>&amp;handsetid=<%= hsId %>">Ort suchen</a></li>
    </ul>
</body>
</html>