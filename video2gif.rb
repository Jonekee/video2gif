#!/usr/bin/env ruby
require 'rubygems'
require 'ArgsParser'

parser = ArgsParser.parser
parser.bind(:input, :i, 'input video file')
parser.bind(:output, :o, 'output gif file : default - out.gif')
parser.bind(:size, :s, 'size : default - 400x300')
parser.comment(:tmp_dir, 'tmp dir : default - /var/tmp/video2gif')
parser.bind(:video_fps, :vfps, 'video fps : default - 30')
parser.bind(:gif_fps, :gfps, 'gif fps : default - 10')
parser.comment(:max_frames, 'max frames : default - -1 (no limit)')
parser.bind(:help, :h, 'show help')
first, params = parser.parse(ARGV)

if !parser.has_param(:input) or parser.has_option(:help)
  puts parser.help
  exit
end

{
  :output => 'out.gif',
  :size => '400x300',
  :video_fps => 2,
  :gif_fps => 6,
  :max_frames => -1,
  :tmp_dir => '/var/tmp/video2gif'
}.each{|k,v|
  params[k] = v unless params[k]
}

Dir.mkdir params[:tmp_dir] unless File.exists? params[:tmp_dir]
Dir.glob(params[:tmp_dir]+'/*').each{|f|
  File.delete f
}

puts cmd = "ffmpeg -i #{params[:input]} -r #{params[:video_fps]} -s #{params[:size]} -sameq #{params[:tmp_dir]}/%d.gif"
puts `#{cmd}`

max_len = Dir.glob(params[:tmp_dir]+'/*').map{|i|
  i.split('/').last.to_i
}.max.to_s.size

Dir.glob(params[:tmp_dir]+'/*').each{|img|
  dst = File.dirname(img)+'/'+img.split('/').last.to_i.to_s.rjust(max_len,'0')+'.'+img.scan(/\.(.+)$/).first.first
  begin
    File.rename(img, dst)
  rescue => e
    STDERR.puts e
    exit 1
  end
}


if params[:max_frames].to_i > 0
  files = Dir.glob(params[:tmp_dir]+'/*').sort{|a,b|
    a.split('/').last.to_i <=> b.split('/').last.to_i
  }
  while files.size > params[:max_frames].to_i
    File.delete files.shift
  end
end

puts cmd = "convert -colors 32 -resize #{params[:size]} -loop 0 -delay #{100/params[:gif_fps].to_i} #{params[:tmp_dir]}/*.gif #{params[:output]}"
puts `#{cmd}`