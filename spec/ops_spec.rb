require 'spec_helper'
require 'Ops'

describe Ops do
  include HTTParty
  let!(:url){ Ops.new.return_ops_url(1) }
  # let!(:xml){ Ops.return_shoopingcart_xml(1)}
  it "Returns the canvas Url given a template id" do
    #HTTParty.should_receive(:post).with(xml: {key: 1}.to_xml).and_return 'http://localhost:3000/mistemplates/1'
    url.should eql('http://localhost:3000/mistemplates/1')
  end

  # it 'Returns the xml for shopping car' do
  #   xml.should eql('<xml>mixml></xml>')
  # end
end
