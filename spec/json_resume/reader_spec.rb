require 'spec_helper'
require 'json_resume/reader'
require 'json_resume/formatter'

describe "#reader" do
  context "when given a json file name" do
    it 'reads in the file' do
      expect(File).to receive(:read).with('test.json').and_return("{\"test\":1}")
      reader = JsonResume::Reader.new 'test.json', {}
      expect(reader.hash).to eq({"test"=>1})
    end
  end

  context "when given a json string" do
    it 'reads in the string' do
      reader = JsonResume::Reader.new "{\"test\":1}", {}
      expect(reader.hash).to eq({"test"=>1})
    end
  end

  context "when given a JSON URL" do
    it 'fetches the URL instead of treating it as a local file' do
      url = 'https://example.com/resume.json'
      expect(URI).to receive(:open).with(url).and_return("{\"test\":1}")

      reader = JsonResume::Reader.new url, {}

      expect(reader.hash).to eq({"test"=>1})
    end
  end

  context "when doing a format!" do
    it 'updates the hash by calling the proper formatter' do
      expect_any_instance_of(JsonResume::FormatterHtml).to receive(:format).and_return(double(:hash =>{}))
      JsonResume::Reader.new("{\"test\":1}",{}).format!
    end

    it 'updates the hash by calling the proper formatter(Latex)' do
      expect_any_instance_of(JsonResume::FormatterLatex).to receive(:format).and_return(double(:hash =>{}))
      JsonResume::Reader.new("{\"test\":1}", {:output_type=>"latex"}).format!
    end
  end
end
