<%@ page import="java.io.*, java.net.*, java.nio.charset.StandardCharsets, java.nio.file.*, org.json.*, java.time.*" %>
<%
String configPath = application.getRealPath("/WEB-INF/config.json");
File configFile = new File(configPath);

if(!configFile.exists()) {
    out.print("NO CONFIG");
    return;
}

JSONObject root = new JSONObject(
    new String(Files.readAllBytes(configFile.toPath()), StandardCharsets.UTF_8)
);

JSONObject gateways = root.getJSONObject("gateways");

LocalDate today = LocalDate.now();
String end = today.plusDays(3).toString();

int updates = 0;

for(String mac : gateways.keySet()) {

    String safeMac = mac.replace(":", "").toUpperCase();

    JSONObject handsets = gateways.getJSONObject(mac).optJSONObject("handsets");
    if(handsets == null) continue;

    JSONObject cacheRoot = new JSONObject();
    JSONObject hsCache = new JSONObject();

    for(String hsId : handsets.keySet()) {

        JSONObject hs = handsets.getJSONObject(hsId);

        String lat = hs.optString("lat", "49.4");
        String lon = hs.optString("lon", "10.4");

        String api =
            "https://api.brightsky.dev/weather?lat=" + lat +
            "&lon=" + lon +
            "&date=" + today +
            "&last_date=" + end +
            "&units=dwd";

        HttpURLConnection conn = (HttpURLConnection)new URL(api).openConnection();
        conn.setRequestMethod("GET");

        if(conn.getResponseCode() == 200) {

            String json = new String(
                conn.getInputStream().readAllBytes(),
                StandardCharsets.UTF_8
            );

            JSONObject weather = new JSONObject(json);

            JSONObject hsObj = new JSONObject();
            hsObj.put("city", hs.optString("city"));
            hsObj.put("lat", lat);
            hsObj.put("lon", lon);
            hsObj.put("weather", weather.optJSONArray("weather"));

            hsCache.put(hsId, hsObj);
            updates++;
        }
    }

    cacheRoot.put("handsets", hsCache);
    cacheRoot.put("updated", LocalDateTime.now().toString());

    String cacheFilePath =
        application.getRealPath("/WEB-INF/cache_" + safeMac + ".json");

    Files.write(
        Paths.get(cacheFilePath),
        cacheRoot.toString(2).getBytes(StandardCharsets.UTF_8)
    );
}

out.print("UPDATED: " + updates);
%>