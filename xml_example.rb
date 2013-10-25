require 'active_support'
class XmlExamples
  def punch_out_order
    xml = Builder::XmlMarkup.new
    xml.instruct!
    xml.declare! :DOCTYPE, :cXML, :SYSTEM, "http://xml.cXML.org/schemas/cXML/1.2.007/cXML.dtd"
    xml.cxml("xml:lang" => "en-US","playloadID" => "", "timestamp" =>"optional") do
      xml.Header do
        xml.From do
          xml.Credential("domain"=>"DUNS")
          xml.Identity "1364789"
        end
        xml.To do
          xml.Credential("domain"=>"DUNS") do
            xml.Identity "1364789"
          end
        end
        xml.Sender do
          xml.Credential("domain"=>"http://localhost:3000") do
            xml.Identity "PunchoutOrderMessage"
          end
          xml.UserAgent "OrderDesk"
        end
      end
      xml.Message do
        xml.PunchoutOrderMessage do
          xml.BuyerCookie "21345"
        end
        xml.PunchOutOrderMessage do
          xml.BuyerCookie "5460"
          xml.PunchOutOrderMessageHeader("operationAllowed" => "inspect") do
            xml.Total do
              xml.Money("currency" => "USD") { "56778" }
            end
          end
          xml.ITEM do
            xml.ItemIn("quantity" => "34") do
              xml.ItemID do
                xml.SupplierPartID "45667"
              end
              xml.ItemDetail do
                xml.UnitPrice do
                  xml.Money("currency" => "AUD"){ "2.8" }
                end
                xml.Description("xml:lang" => "en") { "123.99" }
                xml.UnitOfMeasure "BX"
                xml.Classification("domain" => "UNSPSC") { "1234" }
                xml.Extrinsic("name" => "ImpositionFile") { "Impfile" }
                xml.Extrinsic("name" => "UserFile") { "File" }
                xml.Extrinsic("name" => "BackImpositionFile") { "BackFile" }
                xml.Extrinsic("name" => "BackUserFile") { "BackUserFile" }
              end
            end
          end
        end
      end
    end
  end
end
