require 'yaml'
require 'optparse'
require 'digest'

FONT_NAME = 'NotoSansJP-Bold' # download from Google Fonts
# FONT_NAME = 'DotGothic16-Regular'
## Memo: Google Fonts のいくつかは  SIL Open Font License で利用可能
## Memo: M+ FONTS はフリー

FONT_SIZE = 22
ALIGNMENT = 2
# 1: Bottom left
# 2: Bottom center
# 3: Bottom right
# 5: Top left
# 6: Top center
# 7: Top right
# 9: Middle left
# 10: Middle center
# 11: Middle right

# セリフ間の秒数
PAD_TIME = 0.25

def get_option
  # default value
  option = {
    input: '',
  }

  option_parser = OptionParser.new do |opt|
    opt.banner = 'ffmpeg'
    opt.on('--input SOURCE_SCRIPT_FILE') { |v| option[:input] = v }
  end

  option_parser.parse(ARGV)
  option
end

option = get_option
p script_data = YAML.load(File.read(option[:input]))




p script_data["name"]

scripts_length = script_data["scripts"].length
script_data["scripts"].each_with_index do |line, index|
  line["text"]
  # 音声ファイル作成
  ## TODO: 音声ファイル作成は別スクリプトに切り出し、切替可能にする。
  has_ssml = line.has_key?("ssml")
  text_type = 'text'
  text_type = 'ssml' if has_ssml
  has_voice_id = line.has_key?("voice-id")
  voice_id = 'Mizuki'
  voice_id = line["voice-id"] if has_voice_id
  text = line["text"]
  text = line["ssml"] if has_ssml
  has_voice_filename = line.has_key?("voice-filename")
  voice_digest = Digest::MD5.hexdigest("#{voice_id}-#{text_type}-#{text}")
  voice_filename = "tmp/#{voice_digest}.mp3"
  voice_filename = line["voice-filename"] if has_voice_filename

  font_style = ''
  font_style = line['font-style'] if line.has_key?('font-style')

  unless File.exist?(voice_filename) then
    puts command_file  = "aws polly synthesize-speech --output-format mp3 --voice-id #{voice_id} --text-type #{text_type} --text '#{text}' #{File.basename(voice_filename)}"
    File.write("./tmp/polly.sh", command_file)
    %x(./tmp/polly.sh)
  end


  # 音声ファイルの時間取得
  command = %Q(ffprobe #{voice_filename} -hide_banner -show_entries format=duration 2> /dev/null | grep duration | sed -e 's/.*=//')
  duration = %x(#{command}).chomp

  # 字幕ファイルの作成する
  duration_second = duration.to_s.split('.')[0].to_i
  duration_milli_second = duration.to_s.split('.')[1].to_i
  duration_format_string = sprintf("%02d:%02d.%d", duration_second / 60, duration_second % 60, duration_milli_second)
  srt =<<-"EOL"
1
00:00:00.000 --> 00:#{duration_format_string}
#{line["text"]}
  EOL
  File.write("./tmp/jimaku.srt", srt)

  # 動画 + 字幕 作成
  duration = (duration.to_f + PAD_TIME).to_s
  puts command = %Q(ffmpeg -r 30 -loop 1 -t #{duration} -i #{line["background"]} -vf "subtitles=./tmp/jimaku.srt:force_style='FontName=#{FONT_NAME},FontSize=#{FONT_SIZE},Alignment=#{ALIGNMENT},#{font_style}'" -vcodec libx264 -pix_fmt yuv420p -y tmp/output.mp4)
  %x(#{command})

  # 動画 + ボイス 作成
  puts command = %Q(ffmpeg -r 30 -i #{voice_filename} -af "apad=pad_dur=#{PAD_TIME}" -ar 44100 -y tmp/adjust-#{File.basename(voice_filename)}.mp3)
  %x(#{command})
  puts command = %Q(ffmpeg -r 30 -i tmp/output.mp4 -i tmp/adjust-#{File.basename(voice_filename)}.mp3 -c:v copy -y tmp/#{script_data["name"]}-#{index}.mp4)
  %x(#{command})
end

%x(rm -rf tmp/list.txt)
0.upto(scripts_length - 1) do |index|
  %x(echo "file #{script_data["name"]}-#{index}.mp4" >> tmp/list.txt)
end

command = %Q(ffmpeg -f concat -i tmp/list.txt -c copy -y ./output/#{script_data["name"]}.mp4)
%x(#{command})
