<%@ page language="java" contentType="application/xhtml+xml; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %>
<%@ page import="java.io.*, org.json.*, java.nio.charset.StandardCharsets" %>
<%
    // 1. Parameter und Header holen
    String ua = request.getHeader("User-Agent");
    String mac = request.getParameter("mac");
    String hsid = request.getParameter("handsetid");

    // 2. Nur ausführen, wenn die Basis sich meldet
    if (ua != null && mac != null && hsid != null) {
        try {
            String path = application.getRealPath("/WEB-INF/config.json");
            File configFileObj = new File(path);
            
            if (configFileObj.exists()) {
                JSONObject menuConfig = new JSONObject(new String(java.nio.file.Files.readAllBytes(configFileObj.toPath()), StandardCharsets.UTF_8));
                JSONObject gatewaysObj = menuConfig.getJSONObject("gateways");

                if (gatewaysObj.has(mac)) {
                    JSONObject hs = gatewaysObj.getJSONObject(mac).getJSONObject("handsets").getJSONObject(hsid);
                    
                    // --- STRING PARSING START ---
                    String[] parts = ua.split("/");
                    String baseModel = parts[0].replace("Gigaset ", "").trim();
                    String fwVersion = "---";
                    String hsModel = "Mobilteil";

                    if (parts.length > 1) {
                        String secondPart = parts[1]; // "42.263.00.000.000;SL750H PRO"
                        if (secondPart.contains(";")) {
                            String[] subParts = secondPart.split(";");
                            fwVersion = subParts[0].trim();
                            hsModel = subParts[1].trim(); 
                        } else {
                            fwVersion = secondPart;
                        }
                    }
                    // --- STRING PARSING ENDE ---

                    // Nur speichern, wenn sich Daten geändert haben
                    if (!hsModel.equals(hs.optString("hs_model")) || !fwVersion.equals(hs.optString("box_fw"))) {
                        hs.put("box_model", baseModel);
                        hs.put("box_fw", fwVersion);
                        hs.put("hs_model", hsModel);
                        
                        try (OutputStreamWriter writer = new OutputStreamWriter(new FileOutputStream(configFileObj), StandardCharsets.UTF_8)) {
                            writer.write(menuConfig.toString(4));
                        }
                    }
                }
            }
        } catch (Exception e) {
            // Fehler im Tomcat Log finden
        }
    }
%>
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//OMA//DTD XHTML Mobile 1.2//EN" "http://www.openmobilealliance.org/tech/DTD/xhtmlmobile12.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<body>
    <ul>
        <li><a href="/info/weather_menu.jsp">Wetter</a></li>
        <li><a href="/info/news.jsp">Nachrichten</a></li>
        <li><a href="/info/zodiac.jsp">Horoskop</a></li>
    </ul>
</body>
</html>