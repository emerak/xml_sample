require 'active_support'
require 'builder'
class Ops
  attr_accesor :duns,:shared_secrete,:user_agent,:buyer_cookie,:cost_center_number,:employ_email,
    :user_name,:template_external_number,:url_return,:order_number
  def initialize
    @duns = "12345"
    @shared_secret = "98765"
    @user_agent = "Inkd.com"
    @buyer_cookie = Session['user']
    @cost_center_number = "12354"
    @employ_email = "johndoe@inkd.com"
    @username = "johndoe"
    @template_external_number = "48098"
    @urlreturn = "http://localhost:3000/templates"
    @order_number = "78983"
    @status = "create"
    create_new_order
  end

  def return_ops_url(ops_template_id)
    xml = convert_to_xml(:key => ops_template_id)
    request_xml = HTTParty.get("http://localhost:3000/requestxmls/receive_xml.xml",:body => xml, :headers => {'Content-type' => 'text/xml'})
    hash = convert_to_hash(request_xml)
    url = hash['siteurl']
  end

  def create_new_order
    xml = Builder::XmlMarkup.new
    xml.instruct!
    xml.declare! :DOCTYPE, :cXML, SYSTEM, "http://xml.cXML.org/schemas/cXML/1.2.007/cXML.dtd"
    xml.cxml("playloadID" => "", "timestamp" =>"optional", "version"=>"1.0","xml:lang" => "en") do
      xml.Header do
        xml.from do
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
      xml.Request("deplymentMode" => "test") do
        xml.PunchOutSetupRequest("operation" => :status) do
          xml.BuyerCookie @buyer_cookie
          xml.Extrinsic('name' => "#{@buyer_cookie}")
        end
      end


    end
    puts xml
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
