#!/bin/bash
RSTUDIO_URL="https://download2.rstudio.org/rstudio-server-rhel-1.0.153-x86_64.rpm"
SHINY_URL="https://download3.rstudio.org/centos5.9/x86_64/shiny-server-1.5.1.834-rh5-x86_64.rpm"
RSTUDIOPORT=8787
MIN_USER_ID=400 # default is 500 starting from 1.0.44, EMR hadoop user id is 498

date > /tmp/rstudio_sparklyr_emr5.tmp
export MAKE='make -j 8'
sudo yum install -y xorg-x11-xauth.x86_64 xorg-x11-server-utils.x86_64 xterm libXt libX11-devel libXt-devel libcurl-devel git compat-gmp4 compat-libffi5 openssl-devel
sudo yum install R R-core R-core-devel R-devel libxml2-devel -y
if [ -f /usr/lib64/R/etc/Makeconf.rpmnew ]; then
  sudo cp /usr/lib64/R/etc/Makeconf.rpmnew /usr/lib64/R/etc/Makeconf
fi
if [ -f /usr/lib64/R/etc/ldpaths.rpmnew ]; then
  sudo cp /usr/lib64/R/etc/ldpaths.rpmnew /usr/lib64/R/etc/ldpaths
fi

mkdir /mnt/r-stuff
cd /mnt/r-stuff

  pushd .
	mkdir R-latest
	cd R-latest
	wget http://cran.r-project.org/src/base/R-latest.tar.gz
	tar -xzf R-latest.tar.gz
	sudo yum install -y gcc gcc-c++ gcc-gfortran
	sudo yum install -y readline-devel cairo-devel libpng-devel libjpeg-devel libtiff-devel
	cd R-3*
	./configure --with-readline=yes --enable-R-profiling=no --enable-memory-profiling=no --enable-R-shlib --with-pic --prefix=/usr --with-x --with-libpng --with-jpeglib --with-cairo --enable-R-shlib --with-recommended-packages=yes
	make -j 8
	sudo make install
  sudo su << BASH_SCRIPT
echo '
export PATH=${PWD}/bin:$PATH
' >> /etc/profile
BASH_SCRIPT
  popd

sudo yum remove cpp64 cpp72
sudo sed -i 's/make/make -j 8/g' /usr/lib64/R/etc/Renviron

# set unix environment variables
sudo su << BASH_SCRIPT
echo '
export HADOOP_HOME=/usr/lib/hadoop
export HADOOP_CMD=/usr/bin/hadoop
export HADOOP_STREAMING=/usr/lib/hadoop-mapreduce/hadoop-streaming.jar
export JAVA_HOME=/etc/alternatives/jre
' >> /etc/profile
BASH_SCRIPT
sudo sh -c "source /etc/profile"

# fix hadoop tmp permission
sudo chmod 777 -R /mnt/var/lib/hadoop/tmp

# fix java binding - R and packages have to be compiled with the same java version as hadoop
sudo R CMD javareconf


# install rstudio
# only run if master node


RSTUDIO_FILE=$(basename $RSTUDIO_URL)
wget $RSTUDIO_URL
sudo yum install --nogpgcheck -y $RSTUDIO_FILE
# change port - 8787 will not work for many companies
sudo sh -c "echo 'www-port=$RSTUDIOPORT' >> /etc/rstudio/rserver.conf"
sudo sh -c "echo 'auth-minimum-user-id=$MIN_USER_ID' >> /etc/rstudio/rserver.conf"
sudo perl -p -i -e "s/= 5../= 100/g" /etc/pam.d/rstudio
sudo rstudio-server stop || true
sudo rstudio-server start

sudo R --no-save << R_SCRIPT
install.packages(c('RJSONIO', 'itertools', 'digest', 'Rcpp', 'functional', 'httr', 'plyr', 'stringr', 'reshape2', 'caTools', 'rJava', 'devtools', 'DBI', 'ggplot2', 'dplyr', 'R.methodsS3', 'Hmisc', 'memoise', 'rjson'),
repos="http://cran.rstudio.com")
# here you can add your required packages which should be installed on ALL nodes
# install.packages(c(''), repos="http://cran.rstudio.com", INSTALL_opts=c('--byte-compile') )
install.packages("devtools")
library(devtools)
devtools::install_github("ohdsi/SqlRender")
devtools::install_github("ohdsi/DatabaseConnector")
devtools::install_github("ohdsi/OhdsiRTools")
devtools::install_github("ohdsi/FeatureExtraction", ref = "v2.0.2")
devtools::install_github("ohdsi/CohortMethod", ref = "v2.5.0")
devtools::install_github("ohdsi/EmpiricalCalibration")
install.packages("drat")
drat::addRepo("OHDSI")
install.packages("PatientLevelPrediction")
R_SCRIPT

SHINY_FILE=$(basename $SHINY_URL)
    wget $SHINY_URL
    sudo yum install --nogpgcheck -y $SHINY_FILE

    sudo R --no-save <<R_SCRIPT
install.packages(c('shiny','rmarkdown'),
repos="http://cran.rstudio.com")
R_SCRIPT

sudo rm -f /tmp/rstudio_sparklyr_emr5.tmp

sudo yum install -y cairo-devel
wget https://repo.continuum.io/archive/Anaconda2-5.1.0-Linux-x86_64.sh
chmod +x Anaconda2-5.1.0-Linux-x86_64.sh
sudo ./Anaconda2-5.1.0-Linux-x86_64.sh -b -p /usr/anaconda2/
sudo yum install -y python-scipy
sudo pip install scipy
sudo pip install sklearn

s3 cp 

while read users; do
	USER=`echo $users | cut -d ' ' -f 1`
	USERPW=`echo $users | cut -d ' ' -f 2`
	sudo adduser $USER 
	sudo sh -c "echo '$USERPW' | passwd --stdin $USER"
done <users.txt




















Currently working UserData?  Remove cpp64 and cpp72 boot up manually?
#!/bin/bash
RSTUDIO_URL="https://download2.rstudio.org/rstudio-server-rhel-1.0.153-x86_64.rpm"
SHINY_URL="https://download3.rstudio.org/centos5.9/x86_64/shiny-server-1.5.1.834-rh5-x86_64.rpm"
RSTUDIOPORT=8787
MIN_USER_ID=400 # default is 500 starting from 1.0.44, EMR hadoop user id is 498

date > /tmp/rstudio_sparklyr_emr5.tmp
export MAKE='make -j 8'
sudo yum install -y xorg-x11-xauth.x86_64 xorg-x11-server-utils.x86_64 xterm libXt libX11-devel libXt-devel libcurl-devel git compat-gmp4 compat-libffi5 openssl-devel
sudo yum install R R-core R-core-devel R-devel -y
if [ -f /usr/lib64/R/etc/Makeconf.rpmnew ]; then
  sudo cp /usr/lib64/R/etc/Makeconf.rpmnew /usr/lib64/R/etc/Makeconf
fi
if [ -f /usr/lib64/R/etc/ldpaths.rpmnew ]; then
  sudo cp /usr/lib64/R/etc/ldpaths.rpmnew /usr/lib64/R/etc/ldpaths
fi

mkdir /mnt/r-stuff
cd /mnt/r-stuff

  pushd .
	mkdir R-latest
	cd R-latest
	wget http://cran.r-project.org/src/base/R-latest.tar.gz
	tar -xzf R-latest.tar.gz
	sudo yum install -y gcc gcc-c++ gcc-gfortran
	sudo yum install -y readline-devel cairo-devel libpng-devel libjpeg-devel libtiff-devel
	cd R-3*
	./configure --with-readline=yes --enable-R-profiling=no --enable-memory-profiling=no --enable-R-shlib --with-pic --prefix=/usr --with-x --with-libpng --with-jpeglib --with-cairo --enable-R-shlib --with-recommended-packages=yes
	make -j 8
	sudo make install
  sudo su << BASH_SCRIPT
echo '
export PATH=${PWD}/bin:$PATH
' >> /etc/profile
BASH_SCRIPT
  popd

sudo sed -i 's/make/make -j 8/g' /usr/lib64/R/etc/Renviron

# set unix environment variables
sudo su << BASH_SCRIPT
echo '
export HADOOP_HOME=/usr/lib/hadoop
export HADOOP_CMD=/usr/bin/hadoop
export HADOOP_STREAMING=/usr/lib/hadoop-mapreduce/hadoop-streaming.jar
export JAVA_HOME=/etc/alternatives/jre
' >> /etc/profile
BASH_SCRIPT
sudo sh -c "source /etc/profile"

# fix hadoop tmp permission
sudo chmod 777 -R /mnt/var/lib/hadoop/tmp

# fix java binding - R and packages have to be compiled with the same java version as hadoop
sudo R CMD javareconf


# install rstudio
# only run if master node


RSTUDIO_FILE=$(basename $RSTUDIO_URL)
wget $RSTUDIO_URL
sudo yum install --nogpgcheck -y $RSTUDIO_FILE
# change port - 8787 will not work for many companies
sudo sh -c "echo 'www-port=$RSTUDIOPORT' >> /etc/rstudio/rserver.conf"
sudo sh -c "echo 'auth-minimum-user-id=$MIN_USER_ID' >> /etc/rstudio/rserver.conf"
sudo perl -p -i -e "s/= 5../= 100/g" /etc/pam.d/rstudio
sudo rstudio-server stop || true
sudo rstudio-server start

sudo R --no-save << R_SCRIPT
install.packages(c('RJSONIO', 'itertools', 'digest', 'Rcpp', 'functional', 'httr', 'plyr', 'stringr', 'reshape2', 'caTools', 'rJava', 'devtools', 'DBI', 'ggplot2', 'dplyr', 'R.methodsS3', 'Hmisc', 'memoise', 'rjson'),
repos="http://cran.rstudio.com")
# here you can add your required packages which should be installed on ALL nodes
# install.packages(c(''), repos="http://cran.rstudio.com", INSTALL_opts=c('--byte-compile') )
R_SCRIPT

SHINY_FILE=$(basename $SHINY_URL)
    wget $SHINY_URL
    sudo yum install --nogpgcheck -y $SHINY_FILE

    sudo R --no-save <<R_SCRIPT
install.packages(c('shiny','rmarkdown'),
repos="http://cran.rstudio.com")
R_SCRIPT

sudo rm -f /tmp/rstudio_sparklyr_emr5.tmp

sudo yum install -y cairo-devel
wget https://repo.continuum.io/archive/Anaconda2-5.1.0-Linux-x86_64.sh
chmod +x Anaconda2-5.1.0-Linux-x86_64.sh
sudo ./Anaconda2-5.1.0-Linux-x86_64.sh -b -p /usr/anaconda2/
sudo yum install -y python-scipy
sudo pip install scipy
sudo pip install sklearn

sudo adduser wigginjs
sudo sh -c "echo 'delphi' | passwd --stdin wigginjs"