# これはなに？

動画を作成するスクリプト

# 動作確認環境

- macOS Big Sur
- ruby 2.7
- aws-cli 2
- ffmpeg 4.4

```sh
% ruby --version
ruby 2.7.2p137 (2020-10-01 revision 5445e04352) [x86_64-darwin20]

% aws --version
aws-cli/2.2.46 Python/3.9.7 Darwin/20.5.0 source/x86_64 prompt/off

% ffmpeg -version
ffmpeg version 4.4 Copyright (c) 2000-2021 the FFmpeg developers
built with Apple clang version 12.0.5 (clang-1205.0.22.9)
```

# やること

## 台本ファイル (YAML ファイル)を作る

```yaml
name: script1
scripts:
  - text: こんにちは！ これは ffmpeg で作った動画です。
    ssml: <speak>こんにちは！ これは <sub alias="えふえふえむぺぐ">ffmpeg</sub> で作った動画です。</speak>
    background: chara/aisatsu-2.png
  - text: 2つの動画を組み合わせてみます。
    ssml: <speak>2つの動画を組み合わせてみます。</speak>
    background: chara/aisatsu-1.png
```

## 実行する

```sh
$ ruby main.rb --input daihon/daihon1.yml
```

output ディレクトリ以下に動画ファイルが作成される。


# 中でやっていること

- セリフごとに動画を作成する
  - 音声ファイルを作成する
  - 音声ファイルの時間を取得する
  - 字幕ファイルの作成する
  - 静止画を動画化し、字幕を付ける
  - 動画に音声を付ける
- すべての動画ができたら結合する

## 音声ファイルを作成する

Amazon Polly を利用する。

```sh
$ aws polly synthesize-speech --output-format mp3 --voice-id Mizuki --text-type ssml --text '#{ssml}' voice.mp3
```

## 音声ファイルの時間を取得する

`ffmpeg` 付属の `ffprobe` を利用する。

```sh
$ ffprobe voice.mp3 -hide_banner -show_entries format=duration 2> /dev/null | grep duration
duration=4.1750
```

## 字幕ファイルの作成する

srt ファイルを作成する。

```
1
00:00:00.000 --> 00:00:04.175
text
```

## 静止画を動画化し、字幕を付ける

`ffmpeg`

## 動画に音声を付ける

`ffmpeg`

## すべての動画ができたら結合する

`ffmpeg`

## アップロードする

参考: [YouTubeAPIを利用して動画をアップロードする - Qiita](https://qiita.com/ny7760/items/5a728fd9e7b40588237c)

```sh
pushd youtube_upload
python3 -m venv .venv
./.venv/bin/pip3 install -r requirements.txt
./.venv/bin/python3 upload.py --file="../output/script1.mp4" --title="Sample Movie" --description="This is a sample movie." --category="22" --privacyStatus="private"
popd
```

# LICENSE

MIT

## リポジトリに含まれているリソースについて

chara ディレクトリ以下に @junjanjon が [VRoid](https://vroid.com/) で作成したキャラクターの画像があります。サンプル用です。
