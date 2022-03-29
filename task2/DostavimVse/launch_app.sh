sleep 100
java -jar target/dostavimvse-0.0.1-SNAPSHOT.jar
mvn package -P web-app -D skipTests
java -jar target/dostavimvse-0.0.1-SNAPSHOT.jar
