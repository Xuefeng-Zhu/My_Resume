require "rbconfig"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec) do |task|
  task.rspec_opts = ["-Ilib", "-Ispec", "--format", "documentation"]
end

desc "Generate the HTML resume from Xuefeng_Zhu_Resume.json"
task :build do
  sh RbConfig.ruby,
     "bin/json_resume",
     "convert",
     "--out=html",
     "Xuefeng_Zhu_Resume.json"
end

desc "Generate resume.pdf with chrome-headless-shell"
task :pdf do
  sh RbConfig.ruby,
     "bin/json_resume",
     "convert",
     "--out=html_pdf",
     "Xuefeng_Zhu_Resume.json"
end

desc "Build and serve the resume locally (HOST=127.0.0.1 PORT=8000)"
task serve: :build do
  host = ENV.fetch("HOST", "127.0.0.1")
  port = ENV.fetch("PORT", "8000")

  sh RbConfig.ruby, "-run", "-e", "httpd", "resume", "-b", host, "-p", port
end

task default: :spec
