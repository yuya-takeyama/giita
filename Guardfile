guard 'livereload' do
  watch(%r{lib/.+\.rb})
  watch(%r{views/.+})
end

guard :test do
  watch(%r{^test/.+_test\.rb$})
  watch('test/test_helper.rb')  { 'test' }
  watch(%r{^lib/(.+)\.rb$}) { |m| "test/unit/#{m[1]}_test.rb" }
end
