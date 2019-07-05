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

def enqueue(file_list, q)
  file_list.each do |fn|
    q.push(fn)
  end
  q.push(false)
end

def apply_loop(filter, q)
  while fn = q.pop
    Thread.pass
    apply_one_file(filter, fn)
  end
  q.push(false)
end

def nworker
  1
end

def main(argv)
  filter = argv.shift
  file_list = argv.empty? ? STDIN.to_a.map{|x| x.strip} : argv
  q = Queue.new
  th = (1..nworker).map{Thread.start {apply_loop(filter, q)}}
  enqueue(file_list, q)
  th.each_with_index do |t, i|
    t.join
    Thread.pass
  end
end

main(ARGV)
