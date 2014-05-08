FROM ubuntu:trusty

MAINTAINER: Giuliano Tortoreto giulian.trt@gmail.com

RUN apt-get -y -q update
#download and install java
RUN apt-get -y -q install wget make ant g++ software-properties-common

RUN echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections ; echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections
RUN add-apt-repository 'deb http://ppa.launchpad.net/webupd8team/java/ubuntu precise main'; apt-get update -y -q; apt-get install -y --force-yes -q oracle-java7-installer

# a mounted file systems table to make MySQL happy
#RUN cat /proc/mounts > /etc/mtab

# Install gdal dependencies provided by Ubuntu repositories
RUN apt-get install -y -q \
    mysql-server \
    mysql-client \
    python-numpy \
    libpq-dev \
    libpng12-dev \
    libjpeg-dev \
    libgif-dev \
    liblzma-dev \
    libcurl4-gnutls-dev \
    libxml2-dev \
    libexpat-dev \
    libxerces-c-dev \
    libnetcdf-dev \
    netcdf-bin \
    libpoppler-dev \
    gpsbabel \
    swig \
    libhdf4-alt-dev \
    libhdf5-serial-dev \
    libpodofo-dev \
    poppler-utils \
    libfreexl-dev \
    unixodbc-dev \
    libwebp-dev \
    libepsilon-dev \
    liblcms2-2 \
    libpcre3-dev \
    python-dev

#install geos
RUN wget -O - http://download.osgeo.org/geos/geos-3.4.2.tar.bz2 | tar -jx
RUN cd /geos-3.4.2; ./configure -enable-python && make && make install

#install gdal
RUN wget -O - http://download.osgeo.org/gdal/1.11.0/gdal-1.11.0.tar.gz | tar -xz
RUN cd gdal-1.11.0 ; ./configure --with-xerces --with-java=/usr/lib/jvm/java-7-oracle --with-jvm-lib=/usr/lib/jvm/java-7-oracle/jre/lib/amd64/server --with-jvm-lib-add-rpath=yes --with-mdb=yes --with-geos=yes && make && make install; cd swig/java; make ; cp libgdalconstjni.so libgdaljni.so libogrjni.so libosrjni.so /usr/lib/; cd ../../.libs; cp libgdal.so /usr/lib

#install proj
RUN wget -O - http://download.osgeo.org/proj/proj-4.8.0.tar.gz | tar -xz 
RUN cd ./proj-4.8.0; ./configure && make && make install

# download and "mount" OpenRefine
RUN wget -O - --no-check-certificate https://github.com/OpenRefine/OpenRefine/archive/master.tar.gz | tar -xz
RUN mv OpenRefine-master OpenRefine; cd ./OpenRefine ; ant clean build;

EXPOSE 3333
VOLUME ["/mnt/refine"]

RUN apt-get install unzip;

#download extensions
RUN cd ./OpenRefine/extensions; wget -O - --no-check-certificate https://github.com/giTorto/extraCTU-plugin/archive/master.tar.gz | tar -xz; cd ./extraCTU-plugin-master; ant clean build
RUN cd ./OpenRefine/extensions; wget -O - --no-check-certificate https://github.com/giTorto/geoXtension/archive/master.tar.gz | tar -xz; cp ./gdal-1.11.0/swig/java/gdal.jar ./geoXtension-master/module/MOD-INF/lib; cd ./geoXtension-master ; ant clean build
RUN cd ./OpenRefine/extensions; wget -O - --no-check-certificate https://github.com/giTorto/Refine-NER-Extension/archive/master.tar.gz | tar -xz; cd Refine-NER-Extension-master; ant clean build
RUN cd ./OpenRefine/extensions; wget https://github.com/downloads/fadmaa/grefine-rdf-extension/grefine-rdf-extension-0.8.0.zip; unzip grefine-rdf-extension-0.8.0.zip && rm grefine-rdf-extension-0.8.0.zip

#setting ldpath
RUN echo "LD_LIBRARY_PATH=/usr/lib" >> ~/.bashrc && echo "export LD_LIBRARY_PATH" >> ~/.bashrc

RUN cd /usr/local/lib; cp libproj.so libproj.a libproj.la libproj.so.0 libgeos.a libgeos_c.a libgeos_c.la libgeos_c.so libgeos_c.so.1.8.2  libgeos.la libgeos.so /usr/lib; ldconfig

#test gdal and geos
#RUN cd ./gdal-1.11.0/swig/java; make test;


CMD ["OpenRefine/refine", "-i", "0.0.0.0", "-d", "/mnt/refine"]

