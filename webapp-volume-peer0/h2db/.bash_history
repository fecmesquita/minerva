export
set JPDA_ADDRESS=8000
set JPDA_ADDRESS=7777
set JPDA_TRANSPORT=dt_socket
cd bin/
./catalina.sh stop
./catalina.sh jpds start
./catalina.sh jpda start
./catalina.sh stop
export
export JPDA_ADDRESS=7777
export JPDA_TRANSPORT=dt_socket
./catalina.sh stop
./catalina.sh jpda start
./catalina.sh stop
./catalina.sh stop
exit
cd bin/
export JPDA_ADDRESS=7777
export JPDA_TRANSPORT=dt_socket
./catalina.sh 
./catalina.sh stop
./catalina.sh jpda start
exit
cd bin/
export
./catalina.sh stop
export JPDA_TRANSPORT=dt_socket
export
export JPDA_ADDRESS=7777
export
./catalina.sh jpda start
./catalina.sh jpda start
./catalina.sh stop
exit
export JPDA_ADDRESS=7777
export JPDA_TRANSPORT=dt_socket
cd bin
./catalina.sh stop
./catalina.sh stop
./catalina.sh jpda start
./catalina.sh stop
./catalina.sh jpda start
exit
cd bin/
export JPDA_ADDRESS=7777
export JPDA_TRANSPORT=dt_socket
./catalina.sh stop
./catalina.sh jpda start
exit
cd ..
ls
cd mine
cd minerva/
ls
exit
ls
cd webapps/
ls
cd ..
lsof -i :8080
netstat -nlp | grep 8080
apt-get update
apt-get install netstat
apt-get install net-tools
netstat
netstat -nlp | grep 8080
cd bin/
ls
./catalina.sh start
pwd
exit
