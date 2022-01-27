/*
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// scalastyle:off println
package org.apache.spark.examples.streaming

import org.apache.kafka.clients.consumer.ConsumerConfig
import org.apache.kafka.common.serialization.StringDeserializer

import org.apache.spark.SparkConf
import org.apache.spark.rdd._
import org.apache.spark.streaming._
import org.apache.spark.streaming.dstream._
import org.apache.spark.streaming.kafka010._
import scala.io.Source._
import org.apache.spark.SparkContext
import scala.io.Source
import org.apache.spark.sql._
import scala.util._
import math._
import org.apache.spark.sql.SQLContext
//import org.apache.spark.sql.functions._
import org.apache.spark.sql.streaming._
import org.apache.spark.sql.types._
import org.apache.spark.sql.cassandra._
import org.apache.spark.sql.functions.{col, udf}

import com.datastax.oss.driver.api.core.uuid.Uuids // com.datastax.cassandra:cassandra-driver-core:4.0.0
import com.datastax.spark.connector._              // com.datastax.spark:spark-cassandra-connector_2.11:2.4.3

/**
 * Consumes messages from one or more topics in Kafka and does wordcount.
 * Usage: DirectKafkaWordCount <brokers> <topics>
 *   <brokers> is a list of one or more Kafka brokers
 *   <groupId> is a consumer group name to consume from topics
 *   <topics> is a list of one or more kafka topics to consume from
 *
 * Example:
 *    $ bin/run-example streaming.DirectKafkaWordCount broker1-host:port,broker2-host:port \
 *    consumer-group topic1,topic2
 */

 case class RowAll(dep: String, temp_min:Double, temp_Max: Double, temp_avg: Double)

object DirectKafkaWordCount {
  def main (args: Array[String]) {
    if (args.length < 3) {
      System.err.println(s"""
        |Usage: DirectKafkaWordCount <brokers> <groupId> <topics>
        |  <brokers> is a list of one or more Kafka brokers
        |  <groupId> is a consumer group name to consume from topics
        |  <topics> is a list of one or more kafka topics to consume from
        |
        """.stripMargin)
      System.exit(1)
    }

        /** Lazily instantiated singleton instance of SQLContext */
    object SQLContextSingleton {
      @transient private var instance: SQLContext = null

      // Instantiate SQLContext on demand
      def getInstance(sparkContext: SparkContext): SQLContext = synchronized {
        if (instance == null) {
          instance = new SQLContext(sparkContext)
        }
        instance
      }
    }


    StreamingExamples.setStreamingLogLevels()

    val Array(brokers, groupId, topics) = args


    // Create context with 2 second batch interval
    val sparkConf = new SparkConf().setAppName("DirectKafkaWordCount").set("spark.cassandra.connection.host", "127.0.0.1")

    val ssc = new StreamingContext(sparkConf, Seconds(2))
  
    // Create direct kafka stream with brokers and topics
    val topicsSet = topics.split(",").toSet//departements//topics.split(",").toSet
    val kafkaParams = Map[String, Object](
      ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG -> brokers,
      ConsumerConfig.GROUP_ID_CONFIG -> groupId,
      ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG -> classOf[StringDeserializer],
      ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG -> classOf[StringDeserializer])
    
    val messages = KafkaUtils.createDirectStream[String, String](
      ssc,
      LocationStrategies.PreferConsistent,
      ConsumerStrategies.Subscribe[String, String](topicsSet, kafkaParams))

    val weatherStream: DStream[String] = messages.map(x => x.value)


    val weatherStream5sec: DStream[String] = weatherStream.window(Seconds(10))

    val expandedDF = weatherStream5sec.map(row => {var d = row.split(","); (d(0).replace("\"", ""), d(1).replace("\"", "").replace("nan", "0").toDouble)})//.map(row => print(row))
    val mini = expandedDF.reduceByKey(min)
    val maxi = expandedDF.reduceByKey(max)
    val moyenne = expandedDF.mapValues(x => (x, 1)).reduceByKey((x,y) => (x._1 + y._1, x._2 + y._2)).mapValues(x => x._1/ x._2)

    
    val all = mini.join(maxi).join(moyenne)

       all.foreachRDD { rdd =>

            // Get the singleton instance of SQLContext
            val sqlContext = SQLContextSingleton.getInstance(rdd.sparkContext)
            import sqlContext.implicits._

            // Convert RDD[String] to RDD[case class] to DataFrame
            val dataFrame  = rdd.map(w => RowAll(w._1, w._2._1._1, w._2._1._2, w._2._2)).toDF()
            //dataFrameMini.show()

            dataFrame.show()
}

    ssc.start()
    ssc.awaitTermination()
  }
}
