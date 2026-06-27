<%@ page language="java" import="java.awt.*, java.awt.image.*, javax.imageio.*, java.io.*" trimDirectiveWhitespaces="true" %><%
    // 1. WICHTIG: Den voreingestellten Text-Writer von Tomcat komplett leeren, bevor wir Binärdaten senden
    out.clear();
    out = pageContext.pushBody();

    // 2. URL-Analyse: Ermittelt die gewünschte Wetterbedingung direkt aus dem virtuellen Pfad der web.xml (ohne ?-Parameter)
    String requestURI = request.getRequestURI();
    String iconName = "sun"; // Standard-Fallback

    if (requestURI.contains("cloud")) { iconName = "cloud"; }
    else if (requestURI.contains("rain") || requestURI.contains("shower") || requestURI.contains("drizzle")) { iconName = "rain"; }
    else if (requestURI.contains("snow")) { iconName = "snow"; }
    else if (requestURI.contains("thunder") || requestURI.contains("bolt") || requestURI.contains("gewitter")) { iconName = "thunder"; }

    // 3. Pfad zum Spritesheet auflösen (Ordner: /static/icons/)
    String path = application.getRealPath("/static/icons/_spritesheet.png");
    File sheetFile = new File(path);

    if (sheetFile.exists()) {
        try {
            BufferedImage sheet = ImageIO.read(sheetFile);
            
            int size = 42; 
            int col = 0, row = 0;

            // Mapping der Pixel-Koordinaten aus deinem Spritesheet
            String r = iconName.toLowerCase();
            if (r.contains("sun") || r.contains("clear")) { col = 1; row = 1; }
            else if (r.contains("cloud")) { col = 3; row = 2; }
            else if (r.contains("rain")) { col = 2; row = 3; }
            else if (r.contains("snow")) { col = 4; row = 0; }
            else if (r.contains("thunder")) { col = 0; row = 1; }

            // Gewünschtes Wettersymbol ausschneiden
            BufferedImage icon = sheet.getSubimage(col * size, row * size, size, size);
            
            // 4. KORREKTUR FÜR DAS SL750H PRO (N510 IP Pro):
            // Wir skalieren das Bild auf 128x128 Pixel, da die Pro-Mobilteile Mini-Bilder (32x32) im Screensaver verweigern.
            // Zudem erzwingen wir TYPE_BYTE_INDEXED (8-Bit indiziert), da dies die maximale Farbtiefe ist,
            // die die Consumer-Geräte (GO Box 100 mit CX550HX) fehlerfrei parsen können, ohne abzustürzen.
            BufferedImage combined = new BufferedImage(128, 128, BufferedImage.TYPE_BYTE_INDEXED);
            Graphics2D g = combined.createGraphics();
            
            // Hintergrund weiß einfärben, da BMP keine Alphakanal-Transparenz unterstützt
            g.setColor(Color.WHITE); 
            g.fillRect(0, 0, 128, 128);
            
            // Saubere bilineare Skalierung für das Icon aktivieren
            g.setRenderingHint(RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_BILINEAR);
            g.drawImage(icon, 0, 0, 128, 128, null); 
            g.dispose();

            // 5. ÜBERLEBENSWICHTIGE KORREKTUR: Bild zuerst in einen Speicherpuffer schreiben,
            // um die exakte Dateigröße (in Bytes) zu ermitteln, BEVOR der HTTP-Stream gestartet wird.
            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            ImageIO.write(combined, "bmp", baos); // Zwingend als BMP schreiben
            byte[] imageBytes = baos.toByteArray();

            // 6. Strikte Binär-Header für das Telefonsystem setzen (Löst den "hexx"-Textfehler)
            response.setContentType("image/bmp");
            response.setContentLength(imageBytes.length); // Zwingend erforderlich für den Screensaver-RAM
            response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");

            // 7. Die rohen Bild-Bytes unkorrumpiert in den binären Stream jagen
            OutputStream os = response.getOutputStream();
            os.write(imageBytes);
            os.flush();
            os.close();
            
            return; 
        } catch (Exception e) {
            // Im Fehlerfall Ausführung abbrechen
        }
    }
%>
