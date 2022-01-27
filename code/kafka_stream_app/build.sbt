name := "kafka-stream-app"

version := "1.0"

scalaVersion := "2.12.10"

resolvers += "spark-packages" at "https://dl.bintray.com/spark-packages/maven/"
val SPARK_VERSION = "3.0.1"


libraryDependencies += "org.apache.spark" %% "spark-streaming" % SPARK_VERSION % "provided"

libraryDependencies += "org.apache.spark" %% "spark-streaming-kafka-0-10" % SPARK_VERSION


libraryDependencies += "com.datastax.spark" %% "spark-cassandra-connector" % "3.1.0"

libraryDependencies += "com.datastax.spark" % "spark-cassandra-connector_2.12" % "3.1.0"

libraryDependencies += "com.datastax.spark" %% "spark-cassandra-connector" % "2.4.3"
libraryDependencies += "com.datastax.cassandra" % "cassandra-driver-core" % "4.0.0"

libraryDependencies += "org.apache.spark" %% "spark-core" % "2.4.5" % "provided"
libraryDependencies +=	"org.apache.spark" %% "spark-sql" % "2.4.5" % "provided"

