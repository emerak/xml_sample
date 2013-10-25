require 'spec_helper'
require 'Ops'

describe Ops do
  include HTTParty
  hash = {:params => "dummy_params"}
  let!(:url){ Ops.new.return_ops_url(1,hash) }

  it "Returns the canvas Url given a template id" do
    url.should eql('http://localhost:3000/mistemplates/1')
  end
end
