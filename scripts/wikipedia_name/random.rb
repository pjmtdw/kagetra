class RandomName
  @@sei = []
  @@mei = []
  Dir.glob(File.join(File.dirname(__FILE__),"tmp","sei_*.txt")){|fn|
    @@sei += File.readlines(fn)
  }
  Dir.glob(File.join(File.dirname(__FILE__),"tmp","mei_*.txt")){|fn|
    @@mei += File.readlines(fn)
  }
  if @@sei.empty? or @@mei.empty? then
    raise Exception.new("sei_*.txt or mei_*.txt not found")
  end
  def self.choose
    (s1,s2) = @@sei.sample.chomp.split(/\s/)
    (m1,m2) = @@mei.sample.chomp.split(/\s/)
    {
      name: "#{s1}#{m1}",
      furigana: "#{s2}#{m2}"
    }
  end
  def self.choose_sei
    (s1,_) = @@sei.sample.chomp.split(/\s/)
    s1
  end
  def self.choose_mei
    (m1,_) = @@mei.sample.chomp.split(/\s/)
    m1
  end
end
