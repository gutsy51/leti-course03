# Traffic classification - DDoS or benign.
Log research of IDS systems (Intrusion Detection System) for 
detection of abnormal traffic using machine learning.

DDoS data extracted from different public IDS's and concatenated 
with benign (normal) traffic flows.


## Set up
The dataset is private, so you have to be authenticated.

### 1. Get Kaggle API keys
Go to [Kaggle settings](https://www.kaggle.com/settings) -> API -> Create New Token.

After pressing the button will be downloaded `kaggle.json`:
```json
{"username":"YOUR_USERNAME", "key":"YOUR_API_KEY"}
```

### 2. Save API keys
After that, you need to save the keys in the home catalog:

#### Linux/MacOS
```bash
mkdir -p ~/.kaggle
cp path/to/kaggle.json ~/.kaggle/
chmod 600 ~/.kaggle/kaggle.json
```

#### Windows
```shell
mkdir -p $HOME/.kaggle
cp path/to/kaggle.json $HOME/.kaggle/
```

### 3. You're ready to run `ddos_or_not.ipynb`!