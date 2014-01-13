require 'spec_helper'

describe Coinmux::Http do
  before do
    Coinmux::Http.instance.send(:clear_cache)
  end

  describe "#get" do
    let(:http) { Coinmux::Http.instance }
    let(:host) { 'http://valid-host.example.com' }
    let(:path) { '/valid/path.html' }
    let(:code) { 200 }
    let(:content) { 'some content' }
    let(:response) { stub(code: code, content: content) }

    before do
      http.send(:client).stub(:get).with("#{host}#{path}").and_return(response)
    end

    subject { http.get(host, path) }

    context "with 200 response code" do
      it "returns content" do
        expect(subject).to eq(content)
      end
    end

    context "with non-200 response code" do
      let(:code) { 404 }

      it "raises error" do
        expect { subject }.to raise_error(Coinmux::Error)
      end
    end

    context "with invocation of previously invoked url" do
      before do
        http.get(host, path)
      end

      it "return cached value" do
        http.send(:client).should_receive(:get).with("#{host}#{path}").never
        subject
      end
    end
  end
end