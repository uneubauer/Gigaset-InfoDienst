<%@ page language="java"
         contentType="application/xhtml+xml; charset=UTF-8"
         pageEncoding="UTF-8"
         trimDirectiveWhitespaces="true" %>

<%@ page import="java.io.*, java.nio.charset.StandardCharsets, java.nio.file.*, org.json.*" %>

<%
request.setCharacterEncoding("UTF-8");

String macRaw = request.getParameter("mac");
String hsId = request.getParameter("handsetid");
String city = request.getParameter("city");

if(macRaw == null || hsId == null) {
    out.print("ERROR: missing params");
    return;
}

String mac = macRaw.replace(":", "").toUpperCase().trim();

String configPath = application.getRealPath("/WEB-INF/config.json");
File configFile = new File(configPath);

JSONObject root = configFile.exists()
    ? new JSONObject(new String(Files.readAllBytes(configFile.toPath()), StandardCharsets.UTF_8))
    : new JSONObject();

JSONObject gateways = root.optJSONObject("gateways");
if(gateways == null) {
    gateways = new JSONObject();
    root.put("gateways", gateways);
}

JSONObject gateway = gateways.optJSONObject(mac);
if(gateway == null) {
    gateway = new JSONObject();
    gateways.put(mac, gateway);
}

JSONObject handsets = gateway.optJSONObject("handsets");
if(handsets == null) {
    handsets = new JSONObject();
    gateway.put("handsets", handsets);
}

JSONObject hs = handsets.optJSONObject(hsId);
if(hs == null) {
    hs = new JSONObject();
    handsets.put(hsId, hs);
}

hs.put("city", city != null ? city : "Unbekannt");
hs.put("mode", "weather");

Files.write(
    configFile.toPath(),
    root.toString(2).getBytes(StandardCharsets.UTF_8)
);

// Hier schließen wir den Java-Block jetzt sauber und einmalig ab:
%>
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//OMA//DTD XHTML Mobile 1.2//EN"
"http://www.openmobilealliance.org/tech/DTD/xhtml-mobile12.dtd">

<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <title>Gespeichert</title>
</head>
<body>
    <p>Stadt gespeichert:</p>
    <p><b><%= (city != null ? city : "Unbekannt") %></b></p>
    
    <p>
        <a href="weather_menu.jsp?mac=<%=mac%>&amp;handsetid=<%=hsId%>">Zurueck zum Menue</a>
    </p>
</body>
</html>