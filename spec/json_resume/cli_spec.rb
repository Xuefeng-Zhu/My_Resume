require 'fileutils'
require 'json'
require 'open3'
require 'rbconfig'
require 'tmpdir'

describe 'json_resume CLI' do
  let(:project_root) { File.expand_path('../..', __dir__) }
  let(:executable) { File.join(project_root, 'bin', 'json_resume') }
  let(:resume_json) { File.join(project_root, 'Xuefeng_Zhu_Resume.json') }

  def write_fake_renderer(path, body)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, "#!/bin/sh\nset -eu\n#{body}\n")
    FileUtils.chmod(0o755, path)
  end

  def pdf_output_parser
    <<~'SH'
      output=''
      for argument in "$@"; do
        case "$argument" in
          --print-to-pdf=*) output=${argument#*=} ;;
        esac
      done
      test -n "$output"
    SH
  end

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
      expect(index_html).to include('Software Engineer')
      expect(index_html).to include('href="https://github.com/Xuefeng-Zhu"')
      expect(index_html).to include('href="https://github.com/Xuefeng-Zhu/OpenSlot"')
      expect(index_html).to include('href="https://github.com/Xuefeng-Zhu/PromptDock"')
      expect(index_html).to include('href="https://github.com/Xuefeng-Zhu/InboxPilot"')
      expect(index_html).to include('href="https://github.com/Xuefeng-Zhu/ChronoGuard"')
      expect(index_html).to include('href="https://github.com/Xuefeng-Zhu/SheetSQL"')
      project_positions = %w[InboxPilot ChronoGuard OpenSlot PromptDock SheetSQL].map do |project|
        index_html.index(">#{project}</a>")
      end
      expect(project_positions).to eq(project_positions.sort)
      expect(index_html).not_to include('Emergency-Triage')
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
        expect(output).to include('Microsoft')
        expect(output).to include('May 2016')
        expect(output).to include('OpenSlot')
        expect(output).to include('PromptDock')
        expect(output).to include('InboxPilot')
        expect(output).to include('ChronoGuard')
        expect(output).to include('SheetSQL')
        expect(output).not_to include('Emergency-Triage')
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

  it 'generates HTML PDF output with an injected headless renderer' do
    Dir.mktmpdir('json resume pdf spec ') do |destination|
      renderer = File.join(destination, 'tools with spaces', 'fake renderer')
      write_fake_renderer(
        renderer,
        pdf_output_parser + <<~'SH'
          printf '%s\n' '%PDF-1.4' '1 0 obj' '<<>>' 'endobj' 'trailer' '<<>>' '%%EOF' > "$output"
        SH
      )

      stdout, stderr, status = Open3.capture3(
        { 'JSON_RESUME_PDF_RENDERER' => renderer },
        RbConfig.ruby,
        executable,
        'convert',
        '--out=html_pdf',
        resume_json,
        :chdir => destination
      )

      expect(status).to be_success, "#{stdout}\n#{stderr}"
      expect(File.binread(File.join(destination, 'resume.pdf'), 5)).to eq('%PDF-')
      expect(stdout).to include('Generated resume.pdf')
      expect(Dir.glob(File.join(destination, '.json-resume-pdf-*'))).to be_empty
    end
  end

  it 'preserves an existing PDF when the renderer output is invalid' do
    Dir.mktmpdir('json-resume-invalid-pdf-spec') do |destination|
      renderer = File.join(destination, 'fake-renderer')
      write_fake_renderer(
        renderer,
        pdf_output_parser + <<~'SH'
          printf '%s\n' 'not a PDF' > "$output"
        SH
      )
      existing_pdf = File.join(destination, 'resume.pdf')
      File.write(existing_pdf, 'previous PDF')

      stdout, stderr, status = Open3.capture3(
        { 'JSON_RESUME_PDF_RENDERER' => renderer },
        RbConfig.ruby,
        executable,
        'convert',
        '--out=html_pdf',
        resume_json,
        :chdir => destination
      )

      expect(status).not_to be_success
      expect("#{stdout}\n#{stderr}").to include('invalid PDF')
      expect(File.read(existing_pdf)).to eq('previous PDF')
      expect(Dir.glob(File.join(destination, '.json-resume-pdf-*'))).to be_empty
    end
  end

  it 'stops a timed-out renderer without replacing the current PDF' do
    Dir.mktmpdir('json-resume-timeout-pdf-spec') do |destination|
      renderer = File.join(destination, 'fake-renderer')
      write_fake_renderer(renderer, "sleep 5")
      existing_pdf = File.join(destination, 'resume.pdf')
      File.write(existing_pdf, 'previous PDF')

      stdout, stderr, status = Open3.capture3(
        {
          'JSON_RESUME_PDF_RENDERER' => renderer,
          'JSON_RESUME_PDF_TIMEOUT' => '0.2'
        },
        RbConfig.ruby,
        executable,
        'convert',
        '--out=html_pdf',
        resume_json,
        :chdir => destination
      )

      expect(status).not_to be_success
      expect("#{stdout}\n#{stderr}").to include('timed out')
      expect(File.read(existing_pdf)).to eq('previous PDF')
      expect(Dir.glob(File.join(destination, '.json-resume-pdf-*'))).to be_empty
    end
  end

  it 'reports an invalid explicit PDF renderer path' do
    Dir.mktmpdir('json-resume-missing-pdf-spec') do |destination|
      stdout, stderr, status = Open3.capture3(
        { 'JSON_RESUME_PDF_RENDERER' => File.join(destination, 'missing-renderer') },
        RbConfig.ruby,
        executable,
        'convert',
        '--out=html_pdf',
        resume_json,
        :chdir => destination
      )

      expect(status).not_to be_success
      expect("#{stdout}\n#{stderr}").to include('is not an executable file')
      expect(File).not_to exist(File.join(destination, 'resume.pdf'))
    end
  end

  it 'reports an invalid PDF timeout value without starting the renderer' do
    Dir.mktmpdir('json-resume-timeout-value-spec') do |destination|
      renderer = File.join(destination, 'fake-renderer')
      marker = File.join(destination, 'renderer-started')
      write_fake_renderer(renderer, "touch #{marker.inspect}")

      stdout, stderr, status = Open3.capture3(
        {
          'JSON_RESUME_PDF_RENDERER' => renderer,
          'JSON_RESUME_PDF_TIMEOUT' => 'not-a-number'
        },
        RbConfig.ruby,
        executable,
        'convert',
        '--out=html_pdf',
        resume_json,
        :chdir => destination
      )

      expect(status).not_to be_success
      expect("#{stdout}\n#{stderr}").to include('must be a positive number')
      expect(File).not_to exist(marker)
      expect(Dir.glob(File.join(destination, '.json-resume-pdf-*'))).to be_empty
    end
  end
end
