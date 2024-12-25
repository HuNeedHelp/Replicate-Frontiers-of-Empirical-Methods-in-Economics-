import librosa
import soundfile
import os, glob, subprocess
import pandas as pd
import numpy as np
from pandas import DataFrame

def convert_audios(path, target_path):
    for dirpath, _, filenames in os.walk(path):
        for filename in filenames:
            file = os.path.join(dirpath, filename).replace('\\','/')
            if file.endswith(".wav"):
                target_file = target_path+'/'+filename
                if not os.path.isfile(target_file):     ## 检查文件是否已存在
                    command = f"ffmpeg -i {file} -ac 1 -ar 16000 {target_file}"
                    subprocess.call(command, shell=True)
                else:
                    pass
                
def extract_feature(file_name):
    '''
        Extract the following features
            - MFCC (mfcc)
            - Chroma (chroma)
            - MEL Spectrogram Frequency (mel)
            - Contrast (contrast)
            - Tonnetz (tonnetz)
        Not sure if others are useful: spectral_centroid, flatness, rolloff, etc.
    '''
    with soundfile.SoundFile(file_name) as sound_file:
        X = sound_file.read(dtype="float32")
        sample_rate = sound_file.samplerate
        #Short-time Fourier transform
        stft = np.abs(librosa.stft(X))
        result = np.array([])
        #mfcc
        mfccs = np.mean(librosa.feature.mfcc(S=stft, sr=sample_rate, n_mfcc=40).T, axis=0)
        mfccs_df = DataFrame(mfccs.reshape(-1, len(mfccs)))
        mfccs_df.columns=['mfccs'+str(i) for i in range(0,len(mfccs))]
        #chroma
        chroma = np.mean(librosa.feature.chroma_stft(y=X, sr=sample_rate).T,axis=0)
        chroma_df = DataFrame(chroma.reshape(-1, len(chroma)))
        chroma_df.columns=['chroma'+str(i) for i in range(0,len(chroma))]
        #mel
        mel = np.mean(librosa.feature.melspectrogram(y=X, sr=sample_rate).T,axis=0)
        mel_df = DataFrame(mel.reshape(-1, len(mel)))
        mel_df.columns=['mel'+str(i) for i in range(0,len(mel))]
        #contrast
        contrast = np.mean(librosa.feature.spectral_contrast(S=stft, sr=sample_rate).T,axis=0)
        contrast_df = DataFrame(contrast.reshape(-1, len(contrast)))
        contrast_df.columns=['contrast'+str(i) for i in range(0,len(contrast))]
        #tonnetz
        tonnetz = np.mean(librosa.feature.tonnetz(y=librosa.effects.harmonic(X), sr=sample_rate).T,axis=0)
        tonnetz_df = DataFrame(tonnetz.reshape(-1, len(tonnetz)))
        tonnetz_df.columns=['tonnetz'+str(i) for i in range(0,len(tonnetz))]
    return mfccs_df, chroma_df, mel_df, contrast_df, tonnetz_df

original_path = 'C:\\Users\\Hu\Desktop\\Replicate\\ML\\voice\\data\\' #'PATH TO ORIGINAL AUDIO FILES'
target_path = 'C:\\Users\\Hu\\Desktop\\Replicate\\ML\\voice\\training_data\\' #'PATH TO PRE-PROCESSED AUDIO FILES' 
feature_file = 'C:\\Users\\Hu\\Desktop\\Replicate\\ML\\voice\\feature_file.csv' #'CSV FILE TO SAVE FEATURES OF ALL AUDIOS'
"""
- Run this step to convert audio files to mono-channel and sample rate = 16,000HZ
if the files are not already in this format. Else, move to the feature step directly
- Audio files for training should be saved in a folder named "training_data"
- Audio files for prediction shoule be saved in a folder named "prediction_data"
"""
convert_audios(original_path, target_path)

"""
Run this step to extract vocal features from audio files
Do this separately for training and prediction data
"""
final_df = DataFrame()
emotions = ['neutral', 'calm', 'happy', 'sad', 'angry', 'fearful', 'disgust', 'surprised']
int2emotions = {f'{i+1}': e for i, e in enumerate(emotions)} ## 创建映射字典
filenames = glob.glob(target_path+'*.wav')
for filename in filenames:
    mfccs, chroma, mel, contrast, tonnetz=extract_feature(filename)
    rows = pd.concat([mfccs, chroma, mel, contrast, tonnetz], axis=1)
    #get the emotion indicator for training data
    if str(filename).find('training_data')!=-1:
        emotion_code = filename.split('-')[2].replace('.wav','')[-1]
        emotion = int2emotions.get(emotion_code)
        rows['emotion']=emotion
    #get the identifier for each audio files in the prediction data
    elif str(filename).find('prediction_data')!=-1:     ## 这里实际没用，是在voice_model.py中进行数据划分而不是在这里
        fname=filename.split('/')[-1].replace('.wav','')
        rows['item']=np.array(fname)
    final_df=final_df.append(rows)
final_df.to_csv(feature_file,sep='\t', index=False)
