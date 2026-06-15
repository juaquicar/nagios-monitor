
# Configurar Nagstamon

En primer luegar lo instalaremos desde el repositorio oficial con:
```bash
apt install nagstamon
```11/03/2025 14:14
Una vez instalado lo debemos abrir y configurarlo:

* Monitor URL: http://192.168.55.17/nagios
* Monitor CGI URL: http://192.168.55.17/nagios/cgi-bin
* Username: USUARIO  
* Password: Guardado en Keepass

![d390277f.png](:/65d953154a854d328a879ec5d1f98108)

Para añadir que se abrar al iniciar el ordenador en ubuntu accedemos a gnome-session-properties llamando al mismo comando:

```bash
gnome-session-properties 
```
Hacemos click en añadir y ponemos lo siguiente:

  + Nombre: Nagstamon
  + Comando: /usr/bin/nagstamon
  + Comantario: Startup Nagstamon

![77eaa0a7.png](:/9bf799ea172d44fc8a6f33b6490ca029)

Para desactivar las actualizaciones no críticas y solo mostrar los servicios que estén caidos desde hace más de 5 minutos tenemos que añadir el siguiente filtro desde la configuración:

  - Status information: \b(0 critical updates)\b
  - Duration: 0d\s+0h\s+([0-5])m\s+([0-5]?[0-9])s

![8f9fa30e.png](:/fd3c4f9aef374f098759912f43c883e7)

# Añadir nueva monitorización
> [!NOTE]
> Para que la monitorización funcione el puerto 5666 (NRPE) debe estar habilitado desde el servidor al cliente.

Para monitorizar el host lo haremos mediante NRPE, la instalación requiere de archivos de instalación, están todos dentro del archivo **plugins-nagios.tar.gz** y contiene:

 - nrpe-4.1.1.tar.gz
 - nagios-plugins.tar.gz
 - nrpe.cfg
 - custom_check_mem
 - check_service

> La instalación se hará offline para poder instalar la versión requerida y para el caso de que no haya conexión a internet desde la máquina a monitorizar. 

> [!IMPORTANT]
> La instalación debe hacerse desde el usuario root

> [!CAUTION]
> La versión instalada de NRPE debe ser la misma en cliente y servidor.

## 1. Nagios-plugins

Tenemos que pasar el archivo **plugins-nagios.tar.gz** a la máquina que vamos a monitorizar, una vez dentro haremos lo siguiente:

```bash
sudo apt-get update
sudo apt-get install -y autoconf gcc libc6 libmcrypt-dev make libssl-dev wget bc gawk dc build-essential snmp libnet-snmp-perl gettext
cp plugins-nagios.tar.gz /tmp/plugins-nagios-tar.gz
cd /tmp
tar zxf plugins-nagios.tar.gz
cd /tmp/nagios
tar zxf nagios-plugins.tar.gz
cd /tmp/nagios/nagios-plugins-release-2.4.10/
sudo ./tools/setup
sudo ./configure
sudo make
sudo make install
```
Con esto tendremos instalado los plugins base de nagios.


## 2. NRPE

Ahora instalaremos el plugin de NRPE de la siguiente forma:

```bash
cd /tmp/nagios
tar xfz ./nrpe-4.1.1.tar.gz
cd nrpe-4.1.1/
./configure --enable-command-args --with-ssl-lib=/usr/lib/x86_64-linux-gnu/
sudo make all
sudo make install-groups-users
sudo make install
sudo make install-config
sudo make install-init
systemctl enable nrpe
cd ..
cp ./nrpe.cfg /usr/local/nagios/etc/nrpe.cfg
cp ./custom_check_mem /usr/local/nagios/libexec/
chmod 755 /usr/local/nagios/libexec/custom_check_mem
chown nagios:nagios /usr/local/nagios/libexec/custom_check_mem
sudo systemctl start nrpe.service
```
Por último comprobamos si el plugin está funcionando con:
```bash
/usr/local/nagios/libexec/check_nrpe -H 127.0.0.1
```

## 3. Nagios Server
> [!IMPORTANT]
> La configuración nueva debe hacerse desde el usuario root

Una vez que tanto **nagios-plugins** como **nrpe-plguin** esté instalado debemos acceder al servidor de nagios. Para crear el nuevo host y añadir la monitorización base debemos crear su archivo host y añadirlo a un hostgroup, las carpetas de configuración son las siguientes:

 - **nagios.cfg:** Archivo de configuración principal.
 - **hosts/:** Carpeta donde está los archivos de cada host.
- **services/:** Carpeta donde está los archivos de servicio de cada host, hostgroup o servicegroup.
- **hostsGroups/:** Carpeta donde está los archivos de cada hostgroup.
- **objects/:** Carpeta donde está los archivos de comandos, tamplates y otros.

 > [!NOTE]
 > La ruta principal de estos archivos es /usr/local/nagios

Para crear el nuevo host haremos una copia del archivo de configuración de host base que es **localhost.cfg** dentro de la carpeta **hosts/**:
```bash
cp /usr/local/nagios/etc/hosts/localhost.cfg /usr/local/nagios/etc/hosts/NOMBRE_PRINCIPAL.cfg
vim /usr/local/nagios/etc/hosts/NOMBRE_PRINCIPAL.cfg
```
Dentro del archivo lo editaremos modificando el nombre y la dirección IP:
```bash
define host {

    use                     linux-server            ; Name of host template to use
                                                    ; This host definition will inherit all variables that are defined
                                                    ; in (or inherited by) the linux-server host template definition.
    host_name               NOMBRE_PRINCIPAL
    alias                   NOMBRE_ALIAS
    address                 DIRECCION_IP
    contact_groups          telco_contacts o lyntia_contacts
}
```
Luego lo añadiremos al hostGroup, para ello modificamos el archivo **hostsGroups/localhost.cfg** y en la definición del hostgroup **hostgroup_base** añadimos el nombre de la nueva máquina al final de la linea separada por una coma:

```bash
define hostgroup {

    hostgroup_name          hostgroup_base           ; The name of the hostgroup
    alias                   Hostgroup Base          ; Long name of the group
    members                 GestorTickets,PRE_AGIS,Backups,PRE_Fachada,NOMBRE_PRINCIPAL 
}

```

Y despues lo añadimos al grupo de PRE o PRO que corresponda:

```bash
define hostgroup {

    hostgroup_name          pre_group           ; The name of the hostgroup
    members                 GestorTickets,NOMBRE_PRINCIPAL
}

```

Una vez hecho y para que la nueva mñaquina esté visible desde la interfaz web esto solo tenemos que recargar nagios con el comando:
```bash
systemctl reload nagios
```


## Reset passwords

```bash
sudo htpasswd /usr/local/nagios/etc/htpasswd.users nagiosadmin
```