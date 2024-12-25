import numpy as np
import pandas as pd
from transformers import BertTokenizer, TFBertModel
import tensorflow as tf
from tensorflow.keras.layers import *
from tensorflow.keras.models import Model
from sklearn.metrics import classification_report
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelBinarizer
import random as python_random

np.random.seed(1234)
tf.random.set_seed(1234)

"""# Import and split training data"""
df = pd.read_csv("./FED_classification.csv", sep='\t')
df['cat']=df['sentiment'].apply(lambda x: 2 if x=='dovish' else (0 if x=='hawkish' else 1))

# create balanced sample
hawkish = df[df['sentiment']=='hawkish']
dovish = df[df['sentiment']=='dovish']
neutral = df[df['sentiment']=='neutral']
dovish_downsampled = dovish.sample(hawkish.shape[0])
neutral_downsampled = neutral.sample(hawkish.shape[0])
df_balanced = pd.concat([dovish_downsampled,neutral_downsampled,hawkish])

train, remain = train_test_split(df_balanced, stratify=df_balanced['cat'], train_size=0.8)
test, val = train_test_split(remain, stratify=remain['cat'], train_size=0.5)


"""# Pre-processing data
**Tokenize and store results in arrays to add in dataset later***
"""
# initialize tokenizer
tokenizer = BertTokenizer.from_pretrained('bert-base-uncased')
bert = TFBertModel.from_pretrained('bert-base-uncased')

def tokenize(data):
    seq_len = 512
    num_samples = len(data)

    # initialize empty zero arrays
    Xids = np.zeros((num_samples, seq_len))
    Xmask = np.zeros((num_samples, seq_len)) 

    for i, sentence in enumerate(data['text']):
        tokens = tokenizer.encode_plus(sentence, max_length=seq_len, truncation=True,
                                       padding='max_length', add_special_tokens=True,
                                       return_tensors='tf')
        # assign tokenized outputs to respective rows in numpy arrays
        Xids[i, :] = tokens['input_ids']
        Xmask[i, :] = tokens['attention_mask']
    # check shape
    print(Xids.shape)
    return Xids, Xmask

Xids_train, Xmask_train = tokenize(train)
Xids_val, Xmask_val = tokenize(val)

# This tokenize function is to process testing data later
def prep_data(text):
    tokens = tokenizer.encode_plus(text, max_length=512, truncation=True,
                                   padding='max_length', add_special_tokens=True,
                                   return_token_type_ids=False,
                                   return_tensors='tf')
    # tokenizer returns int32 tensors, we need to return float64, so we use tf.cast
    return {'input_ids': tf.cast(tokens['input_ids'], tf.float64),
            'attention_mask': tf.cast(tokens['attention_mask'], tf.float64)}

# One-hot encoding the sentiment
labels_train = LabelBinarizer().fit_transform(train.cat)
labels_val = LabelBinarizer().fit_transform(val.cat)

"""
Build 2 tf.data.Dataset objects (train & test) using tokenized outputs and label tensors.
Then transform into the correct format for keras input layers
"""

dataset_train = tf.data.Dataset.from_tensor_slices((Xids_train, Xmask_train, labels_train))
dataset_val = tf.data.Dataset.from_tensor_slices((Xids_val, Xmask_val, labels_val))

def map_func(input_ids, masks, labels):
    # convert our three-item tuple into a two-item tuple where the input item is a dictionary
    return {'input_ids': input_ids, 'attention_mask': masks}, labels

dataset_train = dataset_train.map(map_func)
dataset_val = dataset_val.map(map_func)

"""**Batch and shuffle data**"""
# we will split into batches of 10
batch_size = 10

# shuffle and batch
train_ds = dataset_train.shuffle(100).batch(batch_size, drop_remainder=False)
val_ds = dataset_val.shuffle(100).batch(batch_size, drop_remainder=False)

"""# Build and Train"""

"""
    Build a network of which input is the output from BERT

"""

# two input layers for BERT
input_ids = Input(shape=(512,), name='input_ids', dtype='int32')
mask = Input(shape=(512,), name='attention_mask', dtype='int32')

# BERT output layer (use the last hidden state instead of pooler output), use [1] for the pooler output
embeddings = bert.bert(input_ids, attention_mask=mask)[0]

# use BERT outut as input for the next layers
net = Bidirectional(LSTM(512, return_sequences=True, dropout=0.1, recurrent_dropout=0.1))(embeddings)
net = Dropout(0.1)(net)
net = GlobalAveragePooling1D()(net)
net = Dropout(0.1)(net)
net = Dense(512, activation='relu')(net)
net = Dropout(0.1)(net)
net = Dense(128, activation='relu')(net)
out = Dense(3, activation='softmax', name='outputs')(net)

"""
    Initialize model and train
"""
model = Model(inputs=[input_ids, mask], outputs=out)
model.layers[2].trainable = False

model_path='PATH TO FOLDER TO SAVE THE TRAINED MODEL'
optimizer = tf.keras.optimizers.Adam()
loss = tf.keras.losses.CategoricalCrossentropy()
acc = tf.keras.metrics.CategoricalAccuracy('accuracy')
precision = tf.keras.metrics.Precision()
recall = tf.keras.metrics.Recall()

model.compile(optimizer=optimizer,
              loss=loss,
              metrics=[acc, precision, recall])
model_training = model.fit(train_ds,
                           validation_data = val_ds,
                           epochs=200)

model.save(model_path+'text_model', save_format='tf')

"""
    Testing
"""
test['pred'] = None
for i, row in test.iterrows():
    tokens = prep_data(row['text'])
    probs = model.predict(tokens)
    pred = np.argmax(probs)
    test.at[i, 'pred'] = pred

print(classification_report(test.cat.tolist(), test.pred.tolist()))



