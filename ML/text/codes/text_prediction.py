import numpy as np
import pandas as pd
import nltk, re
from nltk.tokenize import word_tokenize, sent_tokenize
from transformers import BertTokenizer, TFBertModel
import tensorflow as tf
from tensorflow.keras.layers import *
from tensorflow.keras.models import Model
from tensorflow.keras.callbacks import ModelCheckpoint, TensorBoard, History, ReduceLROnPlateau, CSVLogger
from sklearn.metrics import classification_report, accuracy_score
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelBinarizer



"""# Pre-processing data

**Tokenize and store results in arrays to add in dataset later***
"""
# initialize tokenizer

# BERT
tokenizer = BertTokenizer.from_pretrained('bert-base-uncased')
bert = TFBertModel.from_pretrained('bert-base-uncased')

# Uncomment the next two lines to use RoBERTa
#tokenizer = RobertaTokenizer.from_pretrained('roberta-base')
#bert = TFRobertaModel.from_pretrained('roberta-base')


seq_len = 512
def prep_data(text):
    tokens = tokenizer.encode_plus(text, max_length=seq_len, truncation=True,
                                   padding='max_length', add_special_tokens=True,
                                   return_token_type_ids=False,
                                   return_tensors='tf')
    # tokenizer returns int32 tensors, we need to return float64, so we use tf.cast
    return {'input_ids': tf.cast(tokens['input_ids'], tf.float64),
            'attention_mask': tf.cast(tokens['attention_mask'], tf.float64)}

def preprocess_text(text):
    text=text.lower()
    text=text.replace('#','')
    text = re.sub('((www\.[^\s]+)|(https?://[^\s]+)|(http?://[^\s]+))', '', text) # remove URLs
    text = re.sub('@[^\s]+', '', text) # remove tagging
    tokens = [word for sent in nltk.sent_tokenize(text) for word in nltk.word_tokenize(sent)]
    processed_text = ''
    for token in tokens:
        if re.search('[a-zA-Z]', token):
            processed_text=processed_text+' '+token
    return processed_text

def prediction(pred_df):
    pred_df['date'] = pd.to_datetime(pred_df['date']).dt.date.astype('datetime64')
    pred_df['sent'] = None
    for i, row in pred_df.iterrows():
        tokens = prep_data(row['text'])
        probs = model.predict(tokens)
        pred = np.argmax(probs)
        pred_df.at[i, 'sent'] = pred
    pred_df = pred_df.drop(columns=['text'])
    return pred_df

"""Load saved model"""
model_path='PATH TO FOLDER WHERE THE TRAINED MODEL WAS SAVED'
model = tf.keras.models.load_model(model_path+'text_model')


#"" Apply on prediction data """
# FED data
output_file = 'OUTPUT FILE FOR FOMC DATA'
input_file = 'path/Replication/Python/text/data/FED_text.xlsx'
'''
    Notes: When using this file to produce sentiment based on RoBERTa,
    the 2nd sheet_name identifier should be changed to _roberta
'''
#answers
pred_df = pd.read_excel(input_file, sheet_name='answers', engine="openpyxl")
pred_df_out = prediction(pred_df)
with pd.ExcelWriter(output_file, mode='w', engine="openpyxl") as writer:
    pred_df_out.to_excel(writer, sheet_name='answers_bert', write_index=False, engine="openpyxl")

#remarks - by paragraph
pred_df = pd.read_excel(input_file, sheet_name='remarks_para', engine="openpyxl")
pred_df_out = prediction(pred_df)
with pd.ExcelWriter(output_file, mode='a', engine="openpyxl") as writer:
    pred_df_out.to_excel(writer, sheet_name='remarks_bert', write_index=False, engine="openpyxl")

#statement - by paragraph
pred_df = pd.read_excel(input_file, sheet_name='statement_para', engine="openpyxl")
pred_df_out = prediction(pred_df)
with pd.ExcelWriter(output_file, mode='a', engine="openpyxl") as writer:
    pred_df_out.to_excel(writer, sheet_name='statement_bert', write_index=False, engine="openpyxl")


# media data
output_file = 'OUTPUT FILE FOR MEDIA DATA'

# FOMC-related news
input_file = 'path/Replication/Python/text/data/news_DO_NOT_DISTRIBUTE.dta'

pred_df = pd.read_stata(input_file)
pred_df_out = prediction(pred_df)
with pd.ExcelWriter(output_file, mode='w', engine="openpyxl") as writer:
    pred_df_out.to_excel(writer, sheet_name='news_sentiment', write_index=False, engine="openpyxl")

# Fed tweets
input_file = 'path/Replication/Python/text/data/tweets_DO_NOT_DISTRIBUTE.dta'

pred_df = pd.read_stata(input_file)
pred_df_out = prediction(pred_df)
with pd.ExcelWriter(output_file, mode='a', engine="openpyxl") as writer:
    pred_df_out.to_excel(writer, sheet_name='tweets_sentiment', write_index=False, engine="openpyxl")
