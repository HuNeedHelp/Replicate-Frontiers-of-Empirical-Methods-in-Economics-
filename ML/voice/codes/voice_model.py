import math
import pandas as pd
from pandas import DataFrame
import numpy as np
import tensorflow as tf
from tensorflow import keras
from tensorflow.keras.layers import LSTM, Dense, Activation, Dropout
from tensorflow.keras.optimizers import SGD, RMSprop, Adam, Adadelta, Adagrad, Adamax, Nadam
from tensorflow.keras.models import Sequential
from tensorflow.keras.callbacks import ModelCheckpoint, TensorBoard, History, ReduceLROnPlateau, CSVLogger
from tensorflow.keras.utils import to_categorical
from sklearn.metrics import accuracy_score, confusion_matrix


def split_data(emotions, filename, train_set):
    df=pd.read_csv(filename, sep='\t')
    # Uncomment to drop a feature
##    df = df.drop([col for col in df.columns if "mfccs" in col], axis=1)
##    df = df.drop([col for col in df.columns if "chroma" in col], axis=1)
##    df = df.drop([col for col in df.columns if "mel" in col], axis=1)
    df = df.drop([col for col in df.columns if "contrast" in col], axis=1)
    df = df.drop([col for col in df.columns if "tonnetz" in col], axis=1)
    '''
        Create balanced training sample
    '''
    y_df = df['emotion']
    count = []
    for emotion in df.emotion.unique():
        if emotion in emotions:
            count.append(len(df[df.emotion == emotion]))

    int2emotions = {i: e for i, e in enumerate(emotions)}   ## 创建两个映射字典
    emotions2int = {v: k for k, v in int2emotions.items()}
    min_count = math.floor(min(count)*train_set)            ## 用于划分训练集和测试集比重
    x_train, x_test = DataFrame(), DataFrame()
    y_train, y_test = DataFrame(columns=['emotion']), DataFrame(columns=['emotion'])
    for emotion in emotions:
        temp = df.loc[df.emotion == emotion]
        train_temp = temp.sample(n=min_count, random_state=100)
        # left df is the "big" one, right df is the sub-set for training, keep if data only appear in the former (i.e., testing data)
        test_temp = pd.merge(temp, train_temp, how='outer', indicator=True).query('_merge == "left_only"').drop('_merge', 1)
        x_train = x_train.append(train_temp.drop(['emotion'], axis=1))
        y_train = y_train.append(DataFrame(train_temp['emotion']))
        x_test = x_test.append(test_temp.drop(['emotion'], axis=1))
        y_test = y_test.append(DataFrame(test_temp['emotion']))

    print('Training features:{}; Training output:{}; Testing features:{}; Testing output:{}'.format(x_train.shape,y_train.shape,x_test.shape,y_test.shape))
    x_train = x_train.to_numpy()
    y_train = y_train.to_numpy()
    x_test = x_test.to_numpy()
    y_test = y_test.to_numpy()
    return int2emotions, emotions2int, x_train, y_train, x_test, y_test

def test_score(y_test, y_pred):
    y_pred = np.argmax(model.predict(x_test))
    y_test = [np.argmax(i, out=None, axis=None) for i in y_test]
    return accuracy_score(y_true=y_test, y_pred=y_pred)

def conf_matrix(y_test, y_pred):
    y_pred = model.predict_classes(x_test)
    y_test = [np.argmax(i, out=None, axis=None) for i in y_test]
    
    return matrix

'''
After expermenting with different types of networks and structure,
we found that a network with fully connected layers (dense layers) worked better.
The codes below are to build such network.
The codes can be modified to build networks with different structures/layers
'''

infile = 'ML/voice/feature_file.csv' #'PATH TO THE CSV FILE CONTAINING EXRACTED FEATURES OF TRAINING AUDIO FILES'
model_path = 'ML/voice/codes/' #'PATH TO FOLDER TO SAVE TRAINED MODELS'

# specify the list of emotions 
emotions = ['neutral', 'calm', 'happy', 'sad', 'angry', 'fearful', 'disgust', 'surprised']

int2emotions, emotions2int, x_train, y_train, x_test, y_test = split_data(emotions, infile, train_set=0.8)  ## 80% training data 
###one hot coder
y_train = to_categorical([emotions2int[str(e[0])] for e in y_train])
y_test = to_categorical([emotions2int[str(e[0])] for e in y_test])
  
'''
    Create neural network
'''
target_class = len(emotions)
input_length = x_train.shape[1]
    
#tuning parameters here
dense_units = 200
dropout = 0.3
loss = 'categorical_crossentropy'
optimizer = 'adam'

## 就用了三层神经网络
model = Sequential()
model.add(Dense(dense_units, input_dim=input_length))
model.add(Dropout(dropout))
model.add(Dense(dense_units))
model.add(Dropout(dropout))
model.add(Dense(dense_units))
model.add(Dropout(dropout))
model.add(Dense(target_class, activation='softmax'))
model.compile(loss=loss, optimizer=optimizer,
              metrics=[tf.keras.metrics.CategoricalAccuracy(),
                       tf.keras.metrics.Precision(),
                       tf.keras.metrics.Recall()])
print(model)        ## 打印模型结构
'''
    Training
'''
checkpointer = ModelCheckpoint(model_path+'voice_model.h5', save_best_only=True, monitor='val_loss')
lr_reduce = ReduceLROnPlateau(monitor='val_loss', factor=0.9, patience=20, min_lr=0.000001)
model_training = model.fit(x_train, y_train,
                           batch_size=64,
                           epochs=1000,
                           validation_data=(x_test, y_test),
                           callbacks=[checkpointer, lr_reduce])

'''
    Checking accuracy score and confusion matrix
'''
y_pred = np.argmax(model.predict(x_test), axis=-1)
y_test = [np.argmax(i, out=None, axis=None) for i in y_test]

print(accuracy_score(y_true=y_test, y_pred=y_pred))

matrix = confusion_matrix(y_test, y_pred,
                          labels=[emotions2int[e] for e in emotions])
matrix = pd.DataFrame(matrix, index=[f"t_{e}" for e in emotions],columns=[f"p_{e}" for e in emotions])
print(matrix)