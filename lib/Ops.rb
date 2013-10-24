require 'active_support'
require 'builder'
class Ops
  attr_accessor :duns,:shared_secrete,:user_agent,:buyer_cookie,:cost_center_number,:employ_email,
    :user_name,:template_external_number,:url_return,:order_number, :start_point
  def initialize
    @duns                     = '12345'
    @shared_secret            = '98765'
    @user_agent               = 'Inkd.com'
    @buyer_cookie             = 'user'
    @cost_center_number       = '12354'
    @employ_email             = 'johndoe@inkd.com'
    @user_name                = 'johndoe'
    @template_external_number = '48098'
    @url_return               = 'http://localhost:3000/templates'
    @order_number             = '78983'
    @status                   = 'create'
    @start_point              = ''
  end

  def return_ops_url(ops_template_id)
    xml         = create_new_order
    request_xml = HTTParty.get("http://localhost:3000/requestxmls/receive_xml.xml",:body => xml, :headers => {'Content-type' => 'text/xml'})
    hash        = convert_to_hash(request_xml)
    url         = hash['cxml']['Response']['PunchOutSetupResponse']['StartPage']['URL']
  end

  def create_new_order
    @extrinc = { 'CostCenter'=> @cost_center_number, 'UserEmail'=> @employ_email, 'UniqueName'=> @user_name, 'StartPoint'=> @start_point }
    xml = Builder::XmlMarkup.new
    xml.instruct!
    xml.declare! :DOCTYPE, :cXML, :SYSTEM, "http://xml.cXML.org/schemas/cXML/1.2.007/cXML.dtd"
    xml.cxml("playloadID" => "", "timestamp" =>"optional", "version"=>"1.0","xml:lang" => "en") do
      xml.Header do
        xml.From do
          xml.Credential("domain"=>"DUNS") do
            xml.Identity @duns
          end
        end
        xml.To do
          xml.Credential("domain"=>"DUNS") do
            xml.Identity
          end
        end
        xml.Sender do
          xml.Credential("domain"=> "NetworkUserId") do
            xml.Identity
            xml.SharedSecret @shared_secret
          end
          xml.UserAgent @user_agent
        end
      end
      xml.Request("deploymentMode" => "test") do
        xml.PunchOutSetupRequest("operation" => "#{@status}") do
          xml.BuyerCookie @buyer_cookie
          @extrinc.each do |k,v|
            xml.Extrinsic(v,'name'=> k)
          end
          xml.BrowserFormPost do
            xml.URL @url_return
          end
          xml.SelectedItem do
            xml.ItemID do
              xml.SupplierPartID @template_external_number
            end
          end
        end
      end
    end
  end

  def return_shoopingcart_xml(ops_template_id)
  end

  def convert_to_xml(hash)
    hash.to_xml.to_s
  end

  def convert_to_hash(xml)
    xml.kind_of?(Hash) ? xml : from_xml(xml)
  end
end
