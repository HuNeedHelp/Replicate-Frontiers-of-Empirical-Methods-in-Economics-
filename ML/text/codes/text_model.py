import numpy as np
import pandas as pd
import os
os.environ['HF_ENDPOINT'] = 'https://hf-mirror.com'
import torch
from transformers import BertTokenizer, BertModel
from torch.utils.data import DataLoader, Dataset
import torch.nn as nn
from sklearn.metrics import classification_report
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelBinarizer
import random

# Set random seeds
np.random.seed(1234)
torch.manual_seed(1234)

"""# Import and split training data"""
df = pd.read_csv("ML/text/data/FED_classification.csv", sep='\t')
df['cat'] = df['sentiment'].apply(lambda x: 2 if x == 'dovish' else (0 if x == 'hawkish' else 1))  # categorize sentiment

# Create balanced sample
hawkish = df[df['sentiment'] == 'hawkish']
dovish = df[df['sentiment'] == 'dovish']
neutral = df[df['sentiment'] == 'neutral']
dovish_downsampled = dovish.sample(hawkish.shape[0], random_state=1234)
neutral_downsampled = neutral.sample(hawkish.shape[0], random_state=1234)
df_balanced = pd.concat([dovish_downsampled, neutral_downsampled, hawkish])

train, remain = train_test_split(df_balanced, stratify=df_balanced['cat'], train_size=0.8, random_state=1234)
test, val = train_test_split(remain, stratify=remain['cat'], train_size=0.5, random_state=1234)

"""# Pre-processing data"""
# Initialize tokenizer
BERT_PATH = "C:\\Users\\Hu\\.cache\\huggingface\\hub\\bert-base-uncased"
tokenizer = BertTokenizer.from_pretrained(BERT_PATH)

class TextDataset(Dataset):
    def __init__(self, data, tokenizer, max_length=512):
        self.data = data
        self.tokenizer = tokenizer
        self.max_length = max_length

    def __len__(self):
        return len(self.data)

    def __getitem__(self, idx):
        row = self.data.iloc[idx]
        text = row['text']
        label = row['cat']
        tokens = self.tokenizer(text, max_length=self.max_length, truncation=True, padding='max_length', return_tensors='pt')
        input_ids = tokens['input_ids'].squeeze(0)
        attention_mask = tokens['attention_mask'].squeeze(0)
        return input_ids, attention_mask, label

train_dataset = TextDataset(train, tokenizer)
val_dataset = TextDataset(val, tokenizer)
test_dataset = TextDataset(test, tokenizer)

train_loader = DataLoader(train_dataset, batch_size=10, shuffle=True)
val_loader = DataLoader(val_dataset, batch_size=10, shuffle=False)

"""# Build Model"""
class BertClassifier(nn.Module):
    def __init__(self):
        super(BertClassifier, self).__init__()
        self.bert = BertModel.from_pretrained('bert-base-uncased')
        self.lstm = nn.LSTM(768, 512, bidirectional=True, batch_first=True, dropout=0.1)
        self.global_avg_pool = nn.AdaptiveAvgPool1d(1)
        self.fc1 = nn.Linear(1024, 512)
        self.fc2 = nn.Linear(512, 128)
        self.fc3 = nn.Linear(128, 3)
        self.dropout = nn.Dropout(0.1)

    def forward(self, input_ids, attention_mask):
        with torch.no_grad():
            outputs = self.bert(input_ids=input_ids, attention_mask=attention_mask)
        hidden_states = outputs.last_hidden_state
        lstm_out, _ = self.lstm(hidden_states)
        pooled = self.global_avg_pool(lstm_out.transpose(1, 2)).squeeze(-1)
        x = self.dropout(torch.relu(self.fc1(pooled)))
        x = self.dropout(torch.relu(self.fc2(x)))
        x = self.fc3(x)
        return x

model = BertClassifier()
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
model.to(device)

criterion = nn.CrossEntropyLoss()
optimizer = torch.optim.Adam(model.parameters(), lr=1e-4)

"""# Train Model"""
def train_model(model, train_loader, val_loader, criterion, optimizer, epochs=10):
    for epoch in range(epochs):
        model.train()
        total_loss = 0
        correct = 0
        for input_ids, attention_mask, labels in train_loader:
            input_ids, attention_mask, labels = input_ids.to(device), attention_mask.to(device), labels.to(device)

            optimizer.zero_grad()
            outputs = model(input_ids, attention_mask)
            loss = criterion(outputs, labels)
            loss.backward()
            optimizer.step()

            total_loss += loss.item()
            correct += (outputs.argmax(1) == labels).sum().item()

        accuracy = correct / len(train_loader.dataset)
        print(f"Epoch {epoch + 1}/{epochs}, Loss: {total_loss:.4f}, Accuracy: {accuracy:.4f}")

        model.eval()
        val_correct = 0
        with torch.no_grad():
            for input_ids, attention_mask, labels in val_loader:
                input_ids, attention_mask, labels = input_ids.to(device), attention_mask.to(device), labels.to(device)
                outputs = model(input_ids, attention_mask)
                val_correct += (outputs.argmax(1) == labels).sum().item()
        val_accuracy = val_correct / len(val_loader.dataset)
        print(f"Validation Accuracy: {val_accuracy:.4f}")

train_model(model, train_loader, val_loader, criterion, optimizer, epochs=10)

"""# Test Model"""
model.eval()
y_true = []
y_pred = []

with torch.no_grad():
    for input_ids, attention_mask, labels in DataLoader(test_dataset, batch_size=10):
        input_ids, attention_mask, labels = input_ids.to(device), attention_mask.to(device), labels.to(device)
        outputs = model(input_ids, attention_mask)
        preds = outputs.argmax(1)
        y_true.extend(labels.cpu().numpy())
        y_pred.extend(preds.cpu().numpy())

print(classification_report(y_true, y_pred))
