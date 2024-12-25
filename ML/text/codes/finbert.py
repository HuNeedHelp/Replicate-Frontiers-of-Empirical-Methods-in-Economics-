import pandas as pd
import numpy as np
import torch
from transformers import AutoTokenizer, AutoModelForSequenceClassification

tokenizer = AutoTokenizer.from_pretrained("ProsusAI/finbert")
model = AutoModelForSequenceClassification.from_pretrained("ProsusAI/finbert")

def prediction(text_df):
    text_list = text_df['text'].to_list()
    inputs = tokenizer(text_list, max_length=512, padding = True, truncation = True, return_tensors='pt')
    outputs = model(**inputs)
    predictions = torch.nn.functional.softmax(outputs.logits, dim=-1)
    model.config.id2label
    positive = predictions[:, 0].tolist()
    negative = predictions[:, 1].tolist()
    neutral = predictions[:, 2].tolist()
    text_df['Positive']=positive
    text_df['Negative']=negative
    text_df['Neutral']=neutral
    text_df['date'] = pd.to_datetime(text_df['date']).dt.date.astype('datetime64')
    text_df = text_df.drop(columns=['text'])
    return text_df


output_file = 'OUTPUT FILE FOR FOMC DATA'
input_file = 'path/Replication/Python/text/data/FED_text.xlsx'

#answers
text_df = pd.read_excel(input_file, sheet_name='answers', engine="openpyxl")
text_df_out = prediction(text_df)
with pd.ExcelWriter(output_file, mode='w', engine="openpyxl") as writer:
    text_df_out.to_excel(writer, sheet_name='answers_finbert', write_index=False, engine="openpyxl")

#remarks - by paragraph
text_df = pd.read_excel(input_file, sheet_name='remarks_para', engine="openpyxl")
text_df_out = prediction(text_df)
with pd.ExcelWriter(output_file, mode='a', engine="openpyxl") as writer:
    text_df_out.to_excel(writer, sheet_name='remarks_finbert', write_index=False, engine="openpyxl")

#statement - by paragraph
text_df = pd.read_excel(input_file, sheet_name='statement_para', engine="openpyxl")
text_df_out = prediction(text_df)
with pd.ExcelWriter(output_file, mode='a', engine="openpyxl") as writer:
    text_df_out.to_excel(writer, sheet_name='statement_finbert', write_index=False, engine="openpyxl")
