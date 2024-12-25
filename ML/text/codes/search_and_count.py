# -*- coding: utf-8 -*-
import re, csv
import numpy as np
import pandas as pd
from nltk.tokenize import sent_tokenize


N_dovish_V_neg = ['inflation expectation', 'interest rate',
                  'bank rate', 'fund rate',
             'price', 'economic activity', 
             'inflation', ' employment']

N_dovish_V_pos = ['unemployment', 'growth',
                  'monetary policy', 'exchange rate',
                  'productivity', 'demand', 'deficit', 'job market']


V_neg = ['anchor', 'target', 'cut', 'subdue',
         'declin', 'decreas', 'reduc', 
         'low', 'drop', 'tighten',
         'fall', 'fell', 'decelerat', 'slow',
         'pause', 'pausing',
         'stable', 'nonaccelerating', 'downward']

V_pos = ['rise', 'rising', 'increas', 'expand', 'improv',
         'strong', 'upward', 'rais', 'high', 'rapid', 'ease', 'easing']

negation = ["weren't", 'were not', 'was not', "wasn't",
            'did not', "didn't", 'do not', "don't",
            'will not', "won't"]




def search_and_count(all_content):
    dovish=[]
    hawkish=[]

    all_text=all_content['text'].tolist()
    
    for text in all_text:
        count_d=0
        count_h=0
        for sent_all in sent_tokenize(text):
            sent_all=sent_all.lower()
            sent_all.replace(';',',').replace('\t',' ').strip()
            for sent in sent_all.split(','):
                if any(word in sent for word in N_dovish_V_neg) and \
                   any(word in sent for word in V_neg) and \
                   not any(word in sent for word in negation):
                    count_d+=1
                if any(word in sent for word in N_dovish_V_pos) and \
                   any(word in sent for word in V_pos) and \
                   not any(word in sent for word in negation):
                    count_d+=1
                if any(word in sent for word in N_dovish_V_neg) and \
                   any(word in sent for word in V_neg) and \
                   any(word in sent for word in negation):
                    count_h+=1
                if any(word in sent for word in N_dovish_V_pos) and \
                   any(word in sent for word in V_pos) and \
                   any(word in sent for word in negation):
                    count_h+=1

                if any(word in sent for word in N_dovish_V_neg) and \
                   any(word in sent for word in V_pos) and \
                   not any(word in sent for word in negation):
                    count_h+=1
                if any(word in sent for word in N_dovish_V_pos) and \
                   any(word in sent for word in V_neg) and \
                   not any(word in sent for word in negation):
                    count_h+=1
                if any(word in sent for word in N_dovish_V_neg) and \
                   any(word in sent for word in V_pos) and \
                   any(word in sent for word in negation):
                    count_d+=1
                if any(word in sent for word in N_dovish_V_pos) and \
                   any(word in sent for word in V_neg) and \
                   any(word in sent for word in negation):
                    count_d+=1

        dovish.append(count_d)
        hawkish.append(count_h)
        
    all_content['hawkish']=hawkish
    all_content['dovish']=dovish
    all_content = all_content.drop(columns=['text'])
    return all_content


output_file = 'OUTPUT FILE FOR FOMC DATA'
input_file = 'path/Replication/Python/text/data/FED_text.xlsx'

#answers
all_content = pd.read_excel(input_file, sheet_name='answers', engine="openpyxl")
all_content_out = search_and_count(all_content)
with pd.ExcelWriter(output_file, mode='w', engine="openpyxl") as writer:
    all_content_out.to_excel(writer, sheet_name='answers_count', write_index=False, engine="openpyxl")

#remarks
all_content = pd.read_excel(input_file, sheet_name='remarks', engine="openpyxl")
all_content_out = search_and_count(all_content)
with pd.ExcelWriter(output_file, mode='w', engine="openpyxl") as writer:
    all_content_out.to_excel(writer, sheet_name='remarks_count', write_index=False, engine="openpyxl")

#statement
all_content = pd.read_excel(input_file, sheet_name='statement', engine="openpyxl")
all_content_out = search_and_count(all_content)
with pd.ExcelWriter(output_file, mode='w', engine="openpyxl") as writer:
    all_content_out.to_excel(writer, sheet_name='statement_count', write_index=False, engine="openpyxl")

    
