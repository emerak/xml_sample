require 'active_support'
class Ops
  def return_ops_url(ops_template_id)
    xml = convert_to_xml(:key => ops_template_id)
    request_xml = HTTParty.get("http://localhost:3000/requestxmls/receive_xml.xml",:body => xml, :headers => {'Content-type' => 'text/xml'})
    hash = convert_to_hash(request_xml)
    url = hash['siteurl']
  end

  def convert_to_xml(hash)
    hash.to_xml.to_s
  end

  def convert_to_hash(xml)
    xml.kind_of?(Hash) ? xml : from_xml(xml)
  end
end
