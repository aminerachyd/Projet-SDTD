from time import sleep
from csv import DictReader
from kafka import KafkaProducer
from json import dumps
import pandas as pd

#A lancer plusieurs fois pour simuler plusieurs point d'envoie
producer = KafkaProducer(bootstrap_servers=['localhost:9092'],
                         value_serializer=lambda x: 
                         dumps(x, ensure_ascii=False).encode('utf-8'))

df = pd.read_csv('dataset2021.csv', sep=';')
departement = df["department (name)"]
choice = departement.sample().values[0]
print(choice)

departement = departement.str.strip()
# departement = departement.str.replace(" ", "")
# departement = departement.str.replace("'", "")
# departement = departement.str.normalize("NFKC")
# departement = departement.str.encode('ASCII', 'ignore')
# departement = departement.drop_duplicates()

df = df.loc[df['department (name)'] == choice]
print(df)
for index, row in df.iterrows():
    producer.send("meteo", value=str(row['department (name)'])+ "," +str(row['Température']))
    sleep(1)
