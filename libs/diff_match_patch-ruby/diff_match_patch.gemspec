Gem::Specification.new do |s|
  s.name         = "diff_match_patch"
  s.version      = "0.0.1"
  s.date         = Time.now.utc.strftime("%Y-%m-%d")
  s.homepage     = "https://github.com/nono/diff_match_patch-ruby"
  s.authors      = "Matthias Reitinger"
  s.email        = "reitinge@in.tum.de"
  s.description  = "Port of google-diff-match-patch to Ruby 1.9 "
  s.summary      = "Port of google-diff-match-patch to Ruby 1.9 "
  s.files        = Dir["LICENSE.txt", "diff_match_patch.rb"]
  s.require_path = '.'
end
