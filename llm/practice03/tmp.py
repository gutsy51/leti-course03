import pandas as pd

tweets = pd.read_csv("data.csv")

tweets.head()
len(tweets)

import re

def remove_non_letters(text):

    cleaned_text = re.sub(r'[^а-яА-Я]', ' ', text)
    cleaned_text = re.sub(r'\s+', ' ', cleaned_text)
    cleaned_text = cleaned_text.strip()

    return cleaned_text

import nltk
from nltk.corpus import stopwords

nltk.download('stopwords')

stop_words = set(stopwords.words('russian'))

def remove_stopwords(text):
    words = text.split()
    words = [word for word in words if word.lower() not in stop_words]
    cleaned_text = ' '.join(words)

    return cleaned_text

from pymystem3 import Mystem

mystem = Mystem()

def lemmatize_text(text):

    lemmatized = mystem.lemmatize(text)
    lemmatized_text = ''.join(lemmatized).strip()

    return lemmatized_text

def preprocessing(text):
    clean_text = remove_stopwords(remove_non_letters(text))
    lem_text = lemmatize_text(clean_text)

    return lem_text
tweets['text'] = tweets['text'].apply(preprocessing)
tweets.info()
tweets['text'].iloc[0]
tweets[tweets['text'].str.len() >= 25]
tweets.to_csv('preprocessed_data.csv', index=False, encoding='cp1251')
from sklearn.feature_extraction.text import TfidfVectorizer

tweets = tweets.dropna()


tfidf_vectorizer = TfidfVectorizer()

text_vector = tfidf_vectorizer.fit_transform(tweets['text'])

text_vector
text_vector.todense()
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import train_test_split

X_train, X_test, y_train, y_test = train_test_split(text_vector, tweets['label'].apply(lambda x: int(x)), test_size=0.33, random_state=42)

from sklearn.metrics import classification_report
from sklearn.metrics import RocCurveDisplay
import matplotlib.pyplot as plt

model = LogisticRegression()

model.fit(X_train, y_train)

preds = model.predict(X_test)

print(classification_report(y_test, preds))
roc_display = RocCurveDisplay.from_predictions(y_test, model.predict_proba(X_test)[:,1])
def remove_links(text):
  link_pattern = r'http[s]?://(?:[a-zA-Z]|[0-9]|[$-_@.&+]|[!*\(\),]|(?:%[0-9a-fA-F][0-9a-fA-F]))+'
  cleaned_text = re.sub(link_pattern, '', text)
  return cleaned_text

tweets_noNorm = pd.read_csv("data.csv")
tweets_noNorm['text'] = tweets_noNorm['text'].apply(lambda x: remove_links(x))
tweets_noNorm = tweets_noNorm.dropna()

tfidf_vectorizer = TfidfVectorizer()

text_vector_noNorm = tfidf_vectorizer.fit_transform(tweets_noNorm['text'])

X_train, X_test, y_train, y_test = train_test_split(text_vector_noNorm,
                                                    tweets_noNorm['label'].apply(lambda x: int(x)),
                                                    test_size=0.33, random_state=42)
model_noNorm = LogisticRegression()

model_noNorm.fit(X_train, y_train)

preds = model_noNorm.predict(X_test)

print(classification_report(y_test, preds))
RocCurveDisplay.from_predictions(y_test, model_noNorm.predict_proba(X_test)[:,1])
def final_preprocessing(text):
  no_links = remove_links(text)
  no_stop_words = remove_stopwords(no_links)
  return no_stop_words

final_tweets = pd.read_csv('data.csv')

final_tweets['text'] = final_tweets['text'].apply(lambda x: final_preprocessing(x))

final_tweets = final_tweets.dropna()

tfidf_vectorizer = TfidfVectorizer()

final_text_vector = tfidf_vectorizer.fit_transform(final_tweets['text'])

X_train, X_test, y_train, y_test = train_test_split(final_text_vector,
                                                    final_tweets['label'].apply(lambda x: int(x)),
                                                    test_size=0.3, random_state=42)
from sklearn.model_selection import GridSearchCV
import numpy as np
final_model = GridSearchCV(estimator=LogisticRegression(max_iter=100000),
                           param_grid={'C': np.arange(.8, 1, 0.1)},
                           verbose=50)

final_model.fit(X_train, y_train)

preds = final_model.predict(X_test)

print(classification_report(y_test, preds))
RocCurveDisplay.from_predictions(y_test, final_model.predict_proba(X_test)[:,1])

from sklearn.feature_extraction.text import CountVectorizer

count_vectorizer_tweets = pd.read_csv("data.csv")

tweets_noNorm['text'] = tweets_noNorm['text'].apply(lambda x: final_preprocessing(x))

final_tweets = final_tweets.dropna()

count_vectorizer = CountVectorizer(ngram_range=(2, 2))

count_vectorizer_vector = count_vectorizer.fit_transform(final_tweets['text'])

X_train, X_test, y_train, y_test = train_test_split(count_vectorizer_vector,
                                                    final_tweets['label'].apply(lambda x: int(x)),
                                                    test_size=0.3, random_state=42)
!pip install nltk
for i in range(1,4):
  count_vectorizer = CountVectorizer(ngram_range=(i, i))

  count_vectorizer_vector = count_vectorizer.fit_transform(final_tweets['text'])

  X_train, X_test, y_train, y_test = train_test_split(count_vectorizer_vector,
                                                    final_tweets['label'].apply(lambda x: int(x)),
                                                    test_size=0.3, random_state=42)

  final_model = LogisticRegression(max_iter=1000)

  final_model.fit(X_train, y_train)

  preds = final_model.predict(X_test)

  print(classification_report(y_test, preds))
  RocCurveDisplay.from_predictions(y_test, final_model.predict_proba(X_test)[:,1])
  plt.title(f'{i}-граммы')