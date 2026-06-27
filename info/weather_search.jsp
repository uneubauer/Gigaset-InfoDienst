<%@ page language="java"
         contentType="application/xhtml+xml; charset=UTF-8"
         pageEncoding="UTF-8"
         trimDirectiveWhitespaces="true" %>

<%@ page import="java.io.*,java.nio.charset.StandardCharsets,org.json.*" %>

<%
String mac = request.getParameter("mac");
String hsId = request.getParameter("handsetid");

if(mac == null) mac = "";
if(hsId == null) hsId = "";

JSONArray cities = new JSONArray();

try {
    String cityFile =
        application.getRealPath("/WEB-INF/cities.json");

    File f = new File(cityFile);

    if(f.exists()) {
        String json =
            new String(
                java.nio.file.Files.readAllBytes(f.toPath()),
                StandardCharsets.UTF_8
            );

        JSONObject root = new JSONObject(json);

        if(root.has("cities")) {
            cities = root.getJSONArray("cities");
        }
    }
}
catch(Exception e) {
}
%>

<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//OMA//DTD XHTML Mobile 1.2//EN"
"http://www.openmobilealliance.org/tech/DTD/xhtml-mobile12.dtd">

<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <title>Ort wählen</title>
</head>

<body>


<p><b>Ort wählen</b></p>

<ul>
<% for(int i=0;i<cities.length();i++) {JSONObject city = cities.getJSONObject(i); String name = city.optString("name","Unbekannt"); %>
<li><a href="<%=request.getContextPath()%>weather_save.jsp?mac=<%=mac%>&amp;handsetid=<%=hsId%>&amp;city=<%=java.net.URLEncoder.encode(name,"UTF-8")%>"><%=name%></a></li>
<% }%>
</ul>
</body>
</html>