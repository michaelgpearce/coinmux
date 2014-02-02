require 'spec_helper'

describe Coinmux::Http do
  before do
    Coinmux::Http.instance.send(:clear_cache)
  end

  describe "#get" do
    let(:http) { Coinmux::Http.instance }
    let(:host) { 'http://valid-host.example.com' }
    let(:path) { '/valid/path.html' }
    let(:code) { '200' }
    let(:body) { 'some content' }
    let(:response) { double(code: code, body: body) }

    before do
      Net::HTTP.stub(:get_response).with(URI("#{host}#{path}")).and_return(response)
    end

    subject { http.get(host, path) }

    context "with 200 response code" do
      it "returns body" do
        expect(subject).to eq(body)
      end
    end

    context "with non-200 response code" do
      let(:code) { '404' }

      it "raises error" do
        expect { subject }.to raise_error(Coinmux::Error)
      end
    end

    context "with invocation of previously invoked url" do
      before do
        http.get(host, path)
      end

      it "return cached value" do
        Net::HTTP.stub(:get_response).with(URI("#{host}#{path}")).never
        subject
      end
    end
  end
end