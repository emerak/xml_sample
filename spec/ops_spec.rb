require 'spec_helper'
require 'Ops'

describe Ops do
  include HTTParty
  let!(:url){ Ops.new.return_ops_url(1) }
  it "Returns the canvas Url given a template id" do
    url.should eql('http://localhost:3000/mistemplates/1')
  end

  it "Returns the imagaes generate given a order approval" do

  end
end
