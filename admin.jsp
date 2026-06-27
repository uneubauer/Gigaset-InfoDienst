<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.io.*, org.json.*, java.nio.charset.StandardCharsets, java.util.*" %>
<%
    String path = application.getRealPath("/WEB-INF/config.json");
    JSONObject configData = new JSONObject();
    try {
        File configFile = new File(path);
        if(configFile.exists()) {
            configData = new JSONObject(new String(java.nio.file.Files.readAllBytes(configFile.toPath()), StandardCharsets.UTF_8));
        }
    } catch (Exception e) {}
    
    JSONObject gateways = configData.optJSONObject("gateways");
    if (gateways == null) gateways = new JSONObject();

    String selMac = request.getParameter("mac");
    String selHs = request.getParameter("hsid");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <style>
        :root {
            --gigaset-orange: #ff9900;
            --gigaset-gray: #f9f9f9;
            --border-light: #e0e0e0;
            --text-main: #333;
        }

        body { font-family: 'Segoe UI', Arial, sans-serif; background: white; margin: 0; color: var(--text-main); display: flex; height: 100vh; }
        
        /* Sidebar für Geräteauswahl */
        .sidebar { width: 250px; border-right: 1px solid var(--border-light); padding: 20px; background: var(--gigaset-gray); overflow-y: auto; }
        .device-link { padding: 10px; margin-bottom: 5px; border-radius: 5px; cursor: pointer; border: 1px solid transparent; }
        .device-link.active { background: white; border-color: var(--border-light); font-weight: bold; }

        /* Main Content */
        .container { flex: 1; padding: 60px; overflow-y: auto; text-align: center; }
        
        .header-text { max-width: 600px; margin: 0 auto 50px; font-size: 0.9em; line-height: 1.6; }
        h1 { font-weight: 400; font-size: 2em; margin-bottom: 10px; }
        .orange-line { width: 60px; height: 3px; background: var(--gigaset-orange); margin: 0 auto 30px; }

        /* Kachel Grid */
        .grid { display: flex; justify-content: center; gap: 20px; flex-wrap: wrap; margin-top: 40px; text-align: left; }
        
        .tile {
            background: var(--gigaset-gray); border: 1px solid var(--border-light); border-radius: 10px;
            width: 220px; height: 280px; padding: 20px; cursor: pointer; position: relative;
            transition: background 0.2s; display: flex; flex-direction: column; justify-content: flex-end;
        }
        .tile:hover { background: #f0f0f0; }
        .tile.active { border-color: var(--border-light); background: white; }

        /* Icons & Status */
        .status-icons { position: absolute; top: 15px; right: 15px; display: flex; gap: 8px; }
        .icon-circle { width: 22px; height: 22px; border-radius: 50%; border: 2px solid #ccc; display: flex; align-items: center; justify-content: center; font-size: 12px; color: #ccc; }
        .tile.active .icon-circle.check { background: #2ecc71; border-color: #2ecc71; color: white; }
        
        .main-icon { font-size: 40px; margin-bottom: 15px; }
        .tile-title { font-size: 1.5em; margin-bottom: 5px; }
        .tile-desc { color: var(--gigaset-orange); font-size: 0.9em; }

        /* Suche */
        .search-box { 
            background: var(--gigaset-gray); border: 1px solid var(--border-light); border-radius: 10px;
            width: 100%; max-width: 700px; margin: 40px auto; padding: 20px; display: flex; align-items: center; justify-content: space-between;
        }
        .search-box input { border: none; background: transparent; font-size: 1em; width: 90%; outline: none; }
        .search-icon { color: var(--gigaset-orange); font-size: 1.5em; cursor: pointer; }

        .location-table { display: flex; justify-content: space-between; max-width: 700px; margin: 0 auto; color: black; font-weight: bold; font-size: 0.9em; }

        .view-section { display: none; }
        .view-section.active { display: block; }
    </style>
</head>
<body>

<div class="sidebar">
    <h3 style="padding: 0 10px; color: #666;">Mobilteile</h3>
    <%
        for (String mac : gateways.keySet()) {
            // System-Keys überspringen
            if(mac.length() < 10) continue; 
            
            JSONObject hsMap = gateways.getJSONObject(mac).optJSONObject("handsets");
            if (hsMap != null) {
                for (String hsid : hsMap.keySet()) {
                    JSONObject hs = hsMap.getJSONObject(hsid);
                    boolean active = hsid.equals(selHs) && mac.equals(selMac);
    %>
    <div class="device-link <%= active ? "active" : "" %>" 
     onclick="location.href='admin.jsp?mac=<%=mac%>&hsid=<%=hsid%>'"
     style="padding: 12px 10px; border-bottom: 1px solid #eee;">
    
    <%-- Hier die Logik: Modellname bevorzugen --%>
    <strong>
        <%= hs.optString("hs_model", "Mobilteil " + hsid) %>
    </strong>

    <div style="color: var(--gigaset-orange); font-size: 0.85em; font-weight: bold; margin: 2px 0;">
        ID: <%= hsid %> <%-- Die ID rückt eine Zeile tiefer --%>
    </div>
    
    <div style="font-size: 0.75em; color: #888;">
        Basis: <%= hs.optString("box_model", "Warte auf Sync...") %><br>
        FW: <%= hs.optString("box_fw", "---") %>
    </div>
</div>
    <% } } } %>
</div>

<div class="container">
    <% if (selMac != null) { 
        JSONObject hs = gateways.getJSONObject(selMac).getJSONObject("handsets").getJSONObject(selHs);
    %>
        <div id="view-index" class="view-section active">
            <div class="header-text">Willkommen – Die Konfigurationskarte Ihres Gigaset IP-Telefons. Bitte wählen Sie hier unten die gewünschten Info-Dienste aus.</div>
            <h1>Konfiguration</h1>
            <div class="orange-line"></div>
            
            <div class="grid">
                <div class="tile <%= "weather".equals(hs.optString("mode")) ? "active" : "" %>" onclick="showView('view-weather')">
                    <div class="status-icons">
                        <div class="icon-circle">★</div>
                        <div class="icon-circle check">✓</div>
                    </div>
                    <div class="main-icon">🌦️</div>
                    <div class="tile-title">Wetter</div>
                    <div class="tile-desc">Beschreibung</div>
                </div>
                <div class="tile" onclick="saveQuick('news')">
                    <div class="status-icons"><div class="icon-circle">★</div><div class="icon-circle">✓</div></div>
                    <div class="main-icon">📰</div>
                    <div class="tile-title">Nachrichten</div>
                    <div class="tile-desc">Beschreibung</div>
                </div>
                <div class="tile" onclick="saveQuick('zodiac')">
                    <div class="status-icons"><div class="icon-circle">★</div><div class="icon-circle">✓</div></div>
                    <div class="main-icon">♏</div>
                    <div class="tile-title">Horoskop</div>
                    <div class="tile-desc">Beschreibung</div>
                </div>
            </div>
        </div>

        <div id="view-weather" class="view-section">
            <h2 style="text-align:left; max-width:700px; margin: 0 auto 20px;">Einheiten</h2>
            <div class="grid" style="justify-content: flex-start; max-width:740px; margin: 0 auto;">
                <div class="tile active" id="tile-C" onclick="setUnit('C')" style="height:200px;">
                    <div class="status-icons"><div class="icon-circle check">✓</div></div>
                    <div class="main-icon">°C</div>
                    <div class="tile-title">Celcius</div>
                    <div class="tile-desc">Einheiten für Grad</div>
                </div>
                <div class="tile" id="tile-F" onclick="setUnit('F')" style="height:200px;">
                    <div class="status-icons"><div class="icon-circle">✓</div></div>
                    <div class="main-icon">°F</div>
                    <div class="tile-title">Fahrenheit</div>
                    <div class="tile-desc">Einheiten für Grad</div>
                </div>
            </div>

            <h2 style="text-align:left; max-width:700px; margin: 40px auto 10px;">Stadt</h2>
            <div class="search-box">
                <input type="text" id="cityIn" value="<%= hs.optString("city") %>" placeholder="Geben Sie die Stadt">
                <span class="search-icon" onclick="saveAll()">🔍</span>
            </div>
            <div class="location-table">
                <span>Stadt / Ort</span>
                <span>Bundesland</span>
                <span>Land</span>
            </div>
        </div>
    <% } %>
</div>

<script>
    let unit = 'C';
    function showView(id) {
        document.querySelectorAll('.view-section').forEach(v => v.classList.remove('active'));
        document.getElementById(id).classList.add('active');
    }
    function setUnit(u) {
        unit = u;
        document.getElementById('tile-C').classList.toggle('active', u==='C');
        document.getElementById('tile-F').classList.toggle('active', u==='F');
    }
    function saveAll() {
        const c = document.getElementById('cityIn').value;
        location.href = "info/weather_save.jsp?mac=<%=selMac%>&handsetid=<%=selHs%>&mode=weather&city="+encodeURIComponent(c)+"&unit="+unit;
    }
</script>
</body>
</html>