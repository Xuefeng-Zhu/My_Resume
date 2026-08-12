require 'fileutils'
require 'json'
require 'open3'
require 'rbconfig'
require 'tmpdir'

describe 'json_resume CLI' do
  let(:project_root) { File.expand_path('../..', __dir__) }
  let(:executable) { File.join(project_root, 'bin', 'json_resume') }
  let(:resume_json) { File.join(project_root, 'Xuefeng_Zhu_Resume.json') }

  it 'shows help without loading optional PDF tooling' do
    stdout, stderr, status = Open3.capture3(RbConfig.ruby, executable, 'help')

    expect(status).to be_success, stderr
    expect(stdout).to include('json_resume convert')
  end

  it 'generates a self-contained local HTML entry page' do
    Dir.mktmpdir('json-resume-spec') do |destination|
      stdout, stderr, status = Open3.capture3(
        RbConfig.ruby,
        executable,
        'convert',
        '--out=html',
        resume_json,
        :chdir => destination
      )

      expect(status).to be_success, "#{stdout}\n#{stderr}"

      index_path = File.join(destination, 'resume', 'index.html')
      index_html = File.read(index_path)

      expect(index_html).to include('Xuefeng Zhu')
      expect(index_html).to include('Senior Software Engineer')
      expect(index_html).to include('href="https://github.com/Xuefeng-Zhu"')
      expect(index_html).to include('src="public/images/contact.png"')
      expect(index_html).not_to include('RESUME_CONTENT')
      expect(index_html).not_to include('code.jquery.com')
      expect(File).to exist(File.join(destination, 'resume', 'public', 'css', 'screen.css'))
      expect(File).to exist(File.join(destination, 'resume', 'public', 'images', 'contact.png'))
    end
  end

  it 'writes a usable sample JSON file' do
    Dir.mktmpdir('json-resume-sample-spec') do |destination|
      stdout, stderr, status = Open3.capture3(
        RbConfig.ruby,
        executable,
        'sample',
        :chdir => destination
      )

      expect(status).to be_success, "#{stdout}\n#{stderr}"
      expect(File).to exist(File.join(destination, 'resume.sample.json'))
    end
  end

  it 'keeps the current resume schema intact in Markdown and TeX output' do
    Dir.mktmpdir('json-resume-formats-spec') do |destination|
      %w[md tex].each do |format|
        stdout, stderr, status = Open3.capture3(
          RbConfig.ruby,
          executable,
          'convert',
          "--out=#{format}",
          resume_json,
          :chdir => destination
        )

        expect(status).to be_success, "#{stdout}\n#{stderr}"
      end

      markdown = File.read(File.join(destination, 'resume.md'))
      latex = File.read(File.join(destination, 'resume.tex'))

      expect(markdown).to start_with("## Xuefeng Zhu\n")

      [markdown, latex].each do |output|
        expect(output).to include('ChainScale')
        expect(output).to include('May 2016')
        expect(output).to include('Google Sheet based SQL Engine')
        expect(output).to include('Zahra Mohagehgh')
        expect(output.scan('Bronze Tablet Recipient').length).to eq(1)
      end
    end
  end

  it 'honors an explicit GPA opt-out in every output format' do
    Dir.mktmpdir('json-resume-gpa-spec') do |destination|
      input_path = File.join(destination, 'private-gpa.json')
      File.write(
        input_path,
        JSON.generate(
          'firstname' => 'Private',
          'familyname' => 'Student',
          'bio_data' => {
            'education' => {
              'show_gpa' => false,
              'schools' => [{
                'degree' => 'BS',
                'institution' => 'Example University',
                'year' => '2026',
                'gpa' => '1.23'
              }]
            }
          }
        )
      )

      outputs = {
        'html' => File.join(destination, 'resume', 'index.html'),
        'md' => File.join(destination, 'resume.md'),
        'tex' => File.join(destination, 'resume.tex')
      }

      outputs.each do |format, output_path|
        stdout, stderr, status = Open3.capture3(
          RbConfig.ruby,
          executable,
          'convert',
          "--out=#{format}",
          input_path,
          :chdir => destination
        )

        expect(status).to be_success, "#{stdout}\n#{stderr}"
        expect(File.read(output_path)).not_to include('1.23')
      end
    end
  end
end
