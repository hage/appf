#!/usr/bin/env ruby

def apply_one_file(filter, filename)
  begin
    result = `cat #{filename} | #{filter}`
    raise if $? != 0
    open(filename, 'w') do |f|
      f.print(result)
    end
  rescue => err
    STDERR.puts "#{filename}: #{err.to_s}"
  end
end

def main(argv)
  filter = argv.shift
  file_list = argv.empty? ? STDIN.to_a.map{|x| x.strip} : argv

  file_list.each do |fn|
    apply_one_file(filter, fn)
  end
end

main(ARGV)
