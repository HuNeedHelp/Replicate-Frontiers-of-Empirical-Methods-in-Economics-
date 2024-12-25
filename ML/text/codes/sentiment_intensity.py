from sentence_transformers import SentenceTransformer, util
from sklearn.metrics.pairwise import cosine_similarity
import pandas as pd
import numpy as np

model = SentenceTransformer('all-mpnet-base-v2')
# Create the baseline dovish dimension
dim_data = pd.read_csv('path/Replication/Python/text/data/dictionary.csv', delimiter='\t')
dovish = dim_data['dovish'].tolist()
hawkish = dim_data['hawkish'].tolist()

embeddings1 = model.encode(dovish)
embeddings2 = model.encode(hawkish)
embed_diff = np.subtract(embeddings1, embeddings2)
embed_avr = np.mean(embed_diff, axis=0)

def similarity(df):
    sent = df['text'].tolist()
    embeddings = model.encode(sent)
    simil = cosine_similarity([embed_avr], embeddings)
    df['cosine'] = simil[0]
    df = df.drop(columns=['text'])
    return df


output_file = 'OUTPUT FILE FOR FOMC DATA'
input_file = 'path/Replication/Python/text/data/FED_text.xlsx'
#answers
df = pd.read_excel(input_file, sheet_name='answers', engine="openpyxl")
df_out = similarity(df)
with pd.ExcelWriter(output_file, mode='w', engine="openpyxl") as writer:
    df_out.to_excel(writer, sheet_name='answers_cosine', write_index=False, engine='openpyxl')

#remarks - by paragraph
df = pd.read_excel(input_file, sheet_name='remarks_para', engine="openpyxl")
df_out = similarity(df)
with pd.ExcelWriter(output_file, mode='a', engine="openpyxl") as writer:
    df_out.to_excel(writer, sheet_name='remarks_cosine', write_index=False, engine='openpyxl')

#statement - by paragraph
df = pd.read_excel(input_file, sheet_name='statement_para', engine="openpyxl")
df_out = similarity(df)
with pd.ExcelWriter(output_file, mode='a', engine="openpyxl") as writer:
    df_out.to_excel(writer, sheet_name='statement_cosine', write_index=False, engine='openpyxl')

