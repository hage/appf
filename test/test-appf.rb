# coding: utf-8
require 'minitest/autorun'
require 'minitest/filesystem'
require 'tempfile'

class TestFile
  def initialize(filter, file)
    @filter = filter
    @file = file
    @expect_file = make_expect_file(@file, @filter)
    @testfile = nil
    setup_testfile
  end
  attr_reader :filter

  def setup_testfile
    unlink
    f = Tempfile.create(File.basename(@file))
    f.write(IO.read(@file))
    f.close
    @testfile = f.path
  end

  def test_filename
    @testfile
  end

  def expect_filename
    @expect_file
  end

  def unlink
    File.unlink(@testfile) if @testfile and File.exist?(@testfile)
    @testfile = nil
  end

  private
  def make_expect_file(filename, filter)
    expect_filename = filename + '.expect'
    if !File.exists?(expect_filename) || File.mtime(expect_filename) < File.mtime(filename) || File.mtime(expect_filename) < File.mtime($0)
      system("cat #{filename} | #{filter} > #{expect_filename}")
    end
    expect_filename
  end
end

class TestTestfile < MiniTest::Test
  def rootdir
    File.dirname(File.expand_path($0))
  end

  def setup
    @tf = TestFile.new('head -n1|tr a A', File.join(rootdir, 'test_testdata.txt'))
  end

  def test_exist
    assert_exists @tf.expect_filename
    assert_exists @tf.test_filename
  end

  def test_unlink
    fn = @tf.test_filename.dup
    @tf.unlink
    refute_exists fn
  end

  def test_except_file
    text = IO.readlines(@tf.expect_filename)
    assert_equal 1, text.size
    assert_equal 'Abc', text[0].strip
  end
end

class TestAppf < MiniTest::Test
  def initialize(name)
    super
    @tests = []
    test_data.each do |t|
      t[:files].each do |f|
        @tests << TestFile.new(t[:filter], f)
      end
    end

    appf_path = File.expand_path(File.dirname($0) + '/../appf.rb')
    @appf = "bundle exec ruby #{appf_path}"
  end

  private
  def test_data
    dir = File.expand_path(File.dirname($0))
    [{filter: "grep abc | tr abc ABC", files: ["#{dir}/testdata.txt"]}]
  end

  def common_test
    @tests.each do |t|
      system(yield t)
      assert_exists t.test_filename
      ex = IO.read(t.expect_filename)
      ac = IO.read(t.test_filename)
      assert_equal ex, ac
      t.unlink
    end
  end

  public
  def test_commandline
    common_test do |t|
      "#{@appf} '#{t.filter}' #{t.test_filename}"
    end
  end

  # def test_pipe
  #   common_test do |t|
  #     "cat #{t.test_filename} | #{@appf} '#{t.filter}'"
  #   end
  # end
end
