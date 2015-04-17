# IBR Vagrantbox

Diese Vagrantbox liefert eine lokale Serverumgebung zum Test des Generic Viewers und aller zugehörigen Komponenten einschließlich eines Beispielprojektes (Liebfrauenkirche, Obwerwesel).

## Systemvoraussetzungen zum Betrieb der Box

- Betriebsystem: Windows/MAC/Linux
- Vagrant 1.7.2
- Virtual Box 4.3.26

Die Installation von Vagrant und Virtual Box auf dem Host-Computer kann folgenden Dokumentationen entnommen werden:

- https://www.virtualbox.org/wiki/Documentation
- https://docs.vagrantup.com/v2/installation/index.html

Danach kann dieses Git Repository in ein lokales Verzeichnis geklont und die Box über

```
vagrant up --provision
```

gestartet werden. Die Dauer des Installationsprozesses ist abhängig von der Internetverbindung. Bei der ersten Initialisierung der Box werden ca. 20 GB Daten geladen.

*Hinweis:* Sowohl während des Installationsprozesses der Vagrantbox als auch zum lokalen Betrieb der VM muss der Host-Computer über Internetzugriff verfügen.

Sowohl bei einem _vagrant up_ als auch bei einem _vagrant reload_ sollte immer der _--provision_ Parameter angegeben werden, damit die einzelnen Services auf der Demo VM korrekt gestartet werden.

## Programmkomponenten der Vagrantbox

Die Box basiert auf einem Debian 7 (Wheezy) Betriebssystem. Sie wird mit folgenden Paketen zum lokalen Betrieb der IBR Software ausgestattet:

### Systemkomponenten

- Oracle Java 7
- Maven 3.0
- Apache Tomcat 7.0
- Apache 2.2.22
- mod_jk 1.2.37
- Sesame 2.8.1
- PostgreSQL 9.1
- PostGIS 2.0.6
- MySQL 5.5.41
- Node.js 0.10.29

### IBR Komponenten:

- spatialstore.war
- annotationserver.war
- viewer.zip
- ask.tgz

Alle Java-Webapplikationen werden bei der Initialisierung der VM automatisch in Tomcat deployed.

## Webadressen der Demo VM

Nach erfolgreicher Einrichtung der Vagrantbox sind die IBR Webapplikationen im Browser zu erreichen unter:

```bash
http://localhost:8095/ (Startseite der Demo Box)
```

*Hinweis:* Auf dem Host-Computer sollte kein Programm auf Port 8095 laufen, da es sonst zu Portkonflikten kommt.

Die einzelnen Komponenten können unter folgenden Adressen angesprochen werden:

```bash
- http://localhost:8095/viewer (Generic Viewer)
- http://localhost:8095/spatialstore (Spatialstore)
- http://localhost:8095/annotationserver (Annotationserver)
- http://localhost:8095/openrdf-sesame (Sesame Server)
- http://localhost:8095/openrdf-workbench (Sesame Workbench)
- http://localhost:8095/ask (Ask Client)
- http://localhost:8095/manager (Tomcat Manager)
```

## Beispielprojekt Oberwesel

Zur beispielhaften Arbeit mit dem Generic Viewer steht in der lokalen Umgebung das Referenzprojekt von IBR (Liebfrauenkirche, Oberwesel) zur Verfügung. 
Die Punktwolken und Panoramabilder werden bei der Initialisierung des vagrant Ordners heruntergeladen. Sie werden in die Vagrantbox gelinkt um 
Datenduplikation zu vermeiden. Innerhalb der Box befinden sich die Daten unter nachfolgenden Pfaden.

### Pfade

*Punktwolken*

```bash
/var/tmp/pano/oberwesel/pc/
```

*Screenshots*

```bash
/var/tmp/pano/oberwesel/screenshot/
```

*Intensitäts- und Farbpanoramen*

```bash
/var/www/pano/oberwesel/rgb/
/var/www/pano/oberwesel/rem/
```

### Datenbanken

#### PostgreSQL - Geometriedaten

```bash
Datenbankname: oberwesel
Benutzer: vagrant
Passwort: vagrant
```

#### MySQL - Pundit Notebooks

```bash
Datenbankname: semlibStorage
Benutzer: vagrant
Passwort: vagrant
```

#### Sesame Triple Store - RDF Daten

```bash
Repository: oberwesel
Kein Benutzer/Passwort notwendig
```

## Konfigurationshinweise

Sofern für die IBR Webapplikationen andere Adressen/Ports bzw. Datenbanknamen und -benutzer eingestellt werden sollen, sind in folgenden Dateien manuelle Anpassungen vorzunehmen.

### Generic Viewer

Datei: communicator.js

```bash
\var\lib\tomcat7\webapps\viewer\communicator.js
```

```javascript
GV.Config.spatialstore = "http://localhost:8095/spatialstore/";

GV.Config.spatialstoreURL = GV.Config.spatialstore + "rest/";
GV.OpenID.data = GV.Config.spatialstore + "openid/data";
GV.OpenID.login = GV.Config.spatialstore + "openid/login";
GV.OpenID.logout = GV.Config.spatialstore + "openid/logout";

GV.TRIPLESTORE_API = "http://localhost:8095/openrdf-sesame/repositories/oberwesel";
GV.TRIPLESTORE_GUI = "http://localhost:8095/openrdf-workbench/repositories/oberwesel";
```

### Spatialstore

Datei: config.properties

```bash
/var/lib/tomcat7/webapps/spatialstore/WEB-INF/classes/config.properties
```

```bash
pointcloudpath=/var/tmp/pano/oberwesel/pc/
screenshotpath=/var/tmp/pano/oberwesel/screenshot/

db_host=localhost
db_port=5432
db_database=oberwesel
db_user=vagrant
db_password=vagrant

gv_host=http://localhost:8095
gv_viewer=http://localhost:8095/viewer
gv_rest=http://localhost:8095/spatialstore/rest
gv_openid=http://localhost:8095/openid
gv_viewerjsp=http://localhost:8095/viewer/test.jsp
```

### Annotationserver

Datei: web.xml

```bash
/var/lib/tomcat7/webapps/annotationserver/WEB-INF/web.xml
```

```
    <context-param>
        <description>Repository or DB URL</description>
        <param-name>eu.semlibproject.annotationserver.config.db.url</param-name>
        <param-value>http://localhost:8095/openrdf-sesame/</param-value>
    </context-param>

	[...]

    <context-param>
        <description>RDBMS username</description>
        <param-name>eu.semlibproject.annotationserver.config.rdbms.username</param-name>
        <param-value>vagrant</param-value>
    </context-param>
    <context-param>
        <description>RDBMS password</description>
        <param-name>eu.semlibproject.annotationserver.config.rdbms.password</param-name>
        <param-value>vagrant</param-value>
    </context-param>
```

### ASK

Datei: dojoConfig.js

```bash
/var/www/ask/dojoConfig.js
```

```javascript
    ask: {
        // address of the nodejs instance running the server (js/server/server.js)
        nodeServerAddress: 'http://localhost/ask/',
        nodeServerPort: 53000,

        // Instance of the annotation server to query
        annotationServer: "http://localhost:8095/annotationserver/"

        // demo. is the official dev server
        // annotationServer: "http://demo.as.thepund.it:8080/annotationserver/"

        // metasound is the legacy dev server
        // annotationServer: "http://metasound.dibet.univpm.it:8080/annotationserver/"
    },
```

### Tomcat Manager

Die Tomcat Manager Applikation verwendet folgende Zugangsdaten:

```bash
Benutzer: vagrant
Passwort: vagrant
```